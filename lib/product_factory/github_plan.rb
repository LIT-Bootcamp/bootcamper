# frozen_string_literal: true

module ProductFactory
  GitHubOperation = Data.define(:action, :ticket_id, :issue_number, :attributes) unless const_defined?(:GitHubOperation)

  class GitHubPlan
    TICKET_MARKER = /<!--\s*product-factory-ticket-id:\s*(TICKET-\d{3,})\s*-->/i
    PROJECT_FIELDS = {
      "Idea" => "idea_id",
      "Epic" => "epic_id",
      "Ticket ID" => "id",
      "Priority" => "priority",
      "Status" => "state",
      "Estimate" => "estimate_days",
      "Dependencies" => "dependencies",
      "Source Version" => "current_version",
      "Factory Run" => "factory_run"
    }.freeze
    PROJECT_FIELD_TYPES = {
      "Idea" => "TEXT",
      "Epic" => "TEXT",
      "Ticket ID" => "TEXT",
      "Priority" => "NUMBER",
      "Status" => "SINGLE_SELECT",
      "Estimate" => "NUMBER",
      "Dependencies" => "TEXT",
      "Source Version" => "NUMBER",
      "Factory Run" => "TEXT"
    }.freeze
    STATUS_OPTIONS = %w[draft backlog-ready available in-progress in-review ready-for-human-merge done blocked superseded escalated].freeze

    def initialize(local:, remote:)
      @local = normalize_local(local)
      @remote = remote || {}
    end

    def operations
      operations = schema_operations
      return sorted(operations) if operations.any? { |item| item.action == :escalate }

      issues_by_ticket = remote_issues.filter_map do |issue|
        ids = issue_ticket_ids(issue)
        [ ids.first, issue ] if ids.one?
      end.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
      conflicts = mapping_conflicts(issues_by_ticket)

      (@local.keys | issues_by_ticket.keys | conflicts.keys).sort.each do |ticket_id|
        matches = issues_by_ticket.fetch(ticket_id, [])
        local_ticket = @local[ticket_id]

        if conflicts.key?(ticket_id)
          operations << operation(:escalate, ticket_id, nil,
            "reason" => "ambiguous stable Ticket ID mapping",
            "issue_numbers" => conflicts.fetch(ticket_id).to_a.compact.sort)
          next
        end

        issue = mapped_issue(local_ticket, matches)
        if local_ticket.nil? || local_ticket["state"] == "superseded"
          operations.concat(close_operations(ticket_id, issue)) if issue
          next
        end

        if local_ticket["github_issue"] && issue.nil?
          operations << operation(:escalate, ticket_id, nil,
            "reason" => "recorded GitHub issue mapping is missing",
            "issue_numbers" => [ local_ticket["github_issue"].to_i ])
          next
        end

        missing_projection = missing_projection_fields(local_ticket)
        unless missing_projection.empty?
          operations << operation(:escalate, ticket_id, issue && issue_number(issue),
            "reason" => "canonical ticket projection is incomplete",
            "missing_fields" => missing_projection)
          next
        end

        merged = merged_pull_request(ticket_id)
        if merged && local_ticket["state"] != "done"
          operations << operation(:complete_merged, ticket_id, issue && issue_number(issue),
            "pull_request" => merged["number"], "state" => "done")
          next
        end

        if issue.nil?
          operations << operation(:create, ticket_id, nil, issue_attributes(local_ticket))
          operations << operation(:project_add, ticket_id, nil, {})
          operations.concat(project_field_operations(ticket_id, nil, local_ticket, {}))
          next
        end

        number = issue_number(issue)
        operations << operation(:reopen, ticket_id, number, {}) if closed?(issue) && active_ticket?(local_ticket)

        desired_issue = issue_attributes(local_ticket)
        if issue["title"].to_s != desired_issue["title"] || normalize_body(issue["body"]) != normalize_body(desired_issue["body"])
          operations << operation(:update, ticket_id, number, desired_issue)
        end

        item = project_item(number)
        operations << operation(:project_add, ticket_id, number, {}) unless item
        fields = item ? stringify_keys(item["fields"] || {}) : {}
        operations.concat(project_field_operations(ticket_id, number, local_ticket, fields))
      end

      sorted(operations)
    end

    private

    def normalize_local(local)
      Array(local).to_h do |key, value|
        ticket = stringify_keys(value || {})
        id = ticket["id"] || key.to_s
        [ id, ticket.merge("id" => id) ]
      end
    end

    def remote_issues
      Array(@remote["issues"] || @remote[:issues]).map { |issue| stringify_keys(issue) }
    end

    def issue_ticket_ids(issue)
      ids = issue_marker_ids(issue)
      explicit = issue["ticket_id"].to_s.upcase
      ids << explicit if explicit.match?(/\ATICKET-\d{3,}\z/)
      ids.uniq.sort
    end

    def issue_marker_ids(issue)
      issue["body"].to_s.scan(TICKET_MARKER).flatten.map(&:upcase)
    end

    def mapping_conflicts(issues_by_ticket)
      conflicts = Hash.new { |hash, key| hash[key] = [] }
      issues_by_ticket.each do |ticket_id, issues|
        issues.each { |issue| conflicts[ticket_id] << issue_number(issue) } if issues.length > 1
      end
      remote_issues.each do |issue|
        ids = issue_ticket_ids(issue)
        ids.each { |ticket_id| conflicts[ticket_id] << issue_number(issue) } if ids.length > 1
        markers = issue_marker_ids(issue)
        markers.uniq.each { |ticket_id| conflicts[ticket_id] << issue_number(issue) } if markers.length > markers.uniq.length
      end

      @local.group_by { |_ticket_id, ticket| ticket["github_issue"]&.to_i }.each do |number, tickets|
        next unless number && tickets.length > 1

        tickets.each { |ticket_id, _ticket| conflicts[ticket_id] << number }
      end

      @local.each do |ticket_id, ticket|
        next unless ticket["github_issue"]

        number = ticket["github_issue"].to_i
        issue = remote_issues.find { |candidate| issue_number(candidate) == number }
        ids = issue ? issue_ticket_ids(issue) : []
        next if ids.empty? || ids == [ ticket_id ]

        ([ ticket_id ] + ids).uniq.each { |id| conflicts[id] << number }
      end
      conflicts.transform_values(&:uniq)
    end

    def mapped_issue(local_ticket, matches)
      if local_ticket && local_ticket["github_issue"]
        number = local_ticket["github_issue"].to_i
        remote_issues.find { |issue| issue_number(issue) == number }
      else
        matches.one? ? matches.first : nil
      end
    end

    def close_operations(ticket_id, issue)
      if protected_implementation?(ticket_id)
        [ operation(:escalate, ticket_id, issue_number(issue),
          "reason" => "active branch or pull request protects ticket from closure") ]
      elsif closed?(issue)
        []
      else
        [ operation(:close_superseded, ticket_id, issue_number(issue),
          "reason" => "ticket absent from canonical Git artifacts") ]
      end
    end

    def protected_implementation?(ticket_id)
      branches = Array(@remote["branches"] || @remote[:branches]).map { |branch| stringify_keys(branch) }
      pull_requests = Array(@remote["pull_requests"] || @remote[:pull_requests]).map { |pull_request| stringify_keys(pull_request) }
      branches.any? { |branch| branch["ticket_id"] == ticket_id } ||
        pull_requests.any? { |pull_request| pull_request["ticket_id"] == ticket_id && pull_request["state"].to_s.upcase != "MERGED" && pull_request["state"].to_s.upcase != "CLOSED" }
    end

    def merged_pull_request(ticket_id)
      Array(@remote["pull_requests"] || @remote[:pull_requests]).map { |pull_request| stringify_keys(pull_request) }.find do |pull_request|
        pull_request["ticket_id"] == ticket_id && (pull_request["merged"] == true || pull_request["state"].to_s.upcase == "MERGED")
      end
    end

    def issue_attributes(ticket)
      {
        "title" => ticket.fetch("title").to_s,
        "body" => body_with_marker(ticket["body"], ticket.fetch("id"))
      }
    end

    def body_with_marker(body, ticket_id)
      content = body.to_s.sub(TICKET_MARKER, "").rstrip
      [ content, "<!-- product-factory-ticket-id: #{ticket_id} -->" ].reject(&:empty?).join("\n\n")
    end

    def normalize_body(body)
      body.to_s.gsub("\r\n", "\n").rstrip
    end

    def project_field_operations(ticket_id, issue_number, ticket, remote_fields)
      desired_project_fields(ticket).filter_map do |field, value|
        next if issue_number && remote_fields[field].to_s == value

        operation(:project_field, ticket_id, issue_number, "field" => field, "value" => value)
      end
    end

    def desired_project_fields(ticket)
      PROJECT_FIELDS.to_h do |field, key|
        value = ticket[key]
        value = Array(value).sort.join(", ") if key == "dependencies"
        [ field, value.nil? ? "" : value.to_s ]
      end
    end

    def project_item(issue_number)
      Array(@remote["project_items"] || @remote[:project_items]).map { |entry| stringify_keys(entry) }.find do |entry|
        entry["issue_number"].to_i == issue_number.to_i
      end
    end

    def schema_operations
      fields = @remote.key?("project_fields") || @remote.key?(:project_fields) ? Array(@remote["project_fields"] || @remote[:project_fields]) : nil
      return [ operation(:escalate, nil, nil, "reason" => "GitHub Project field snapshot is missing") ] unless fields

      indexed = fields.map { |field| stringify_keys(field) }.to_h { |field| [ field["name"], field ] }
      PROJECT_FIELD_TYPES.filter_map do |name, data_type|
        field = indexed[name]
        if field.nil?
          attributes = { "field" => name, "data_type" => data_type }
          attributes["options"] = STATUS_OPTIONS if name == "Status"
          operation(:project_field_create, nil, nil, attributes)
        elsif field["data_type"].to_s.upcase != data_type ||
            (name == "Status" && (STATUS_OPTIONS - Array(field["options"]).map(&:to_s)).any?)
          operation(:escalate, nil, nil,
            "reason" => "incompatible GitHub Project field",
            "field" => name,
            "expected_type" => data_type)
        end
      end
    end

    def missing_projection_fields(ticket)
      %w[title body idea_id epic_id factory_run].select { |field| ticket[field].to_s.strip.empty? }
    end

    def active_ticket?(ticket)
      !%w[done superseded].include?(ticket["state"])
    end

    def closed?(issue)
      issue["state"].to_s.upcase == "CLOSED"
    end

    def issue_number(issue)
      value = issue["number"] || issue["issue_number"]
      value && value.to_i
    end

    def operation(action, ticket_id, issue_number, attributes)
      GitHubOperation.new(action, ticket_id, issue_number, attributes)
    end

    def sorted(operations)
      operations.sort_by do |item|
        [ item.ticket_id.to_s, item.action.to_s, item.attributes.fetch("field", ""), item.issue_number.to_i ]
      end
    end

    def stringify_keys(hash)
      hash.to_h { |key, value| [ key.to_s, value ] }
    end
  end
end
