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

    def initialize(local:, remote:)
      @local = normalize_local(local)
      @remote = remote || {}
    end

    def operations
      operations = []
      issues_by_ticket = remote_issues.group_by { |issue| issue_ticket_id(issue) }.reject { |ticket_id, _issues| ticket_id.nil? }
      ambiguous = ambiguous_ticket_ids(issues_by_ticket)

      (@local.keys | issues_by_ticket.keys).sort.each do |ticket_id|
        matches = issues_by_ticket.fetch(ticket_id, [])
        local_ticket = @local[ticket_id]

        if ambiguous.include?(ticket_id) || conflicting_manifest_mapping?(local_ticket, matches)
          operations << operation(:escalate, ticket_id, nil,
            "reason" => "ambiguous stable Ticket ID mapping",
            "issue_numbers" => matches.map { |issue| issue_number(issue) }.compact.sort)
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

        merged = merged_pull_request(ticket_id)
        if merged && local_ticket["state"] != "done"
          operations << operation(:complete_merged, ticket_id, issue && issue_number(issue),
            "pull_request" => merged["number"], "state" => "done")
          next
        end

        if issue.nil?
          operations << operation(:create, ticket_id, nil, issue_attributes(local_ticket))
          operations.concat(project_field_operations(ticket_id, nil, local_ticket, {}))
          next
        end

        number = issue_number(issue)
        operations << operation(:reopen, ticket_id, number, {}) if closed?(issue) && active_ticket?(local_ticket)

        desired_issue = issue_attributes(local_ticket)
        if issue["title"].to_s != desired_issue["title"] || normalize_body(issue["body"]) != normalize_body(desired_issue["body"])
          operations << operation(:update, ticket_id, number, desired_issue)
        end

        fields = project_item_fields(number)
        operations.concat(project_field_operations(ticket_id, number, local_ticket, fields))
      end

      operations.sort_by do |item|
        [ item.ticket_id, item.action.to_s, item.attributes.fetch("field", ""), item.issue_number.to_i ]
      end
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

    def issue_ticket_id(issue)
      explicit = issue["ticket_id"].to_s.upcase
      return explicit if explicit.match?(/\ATICKET-\d{3,}\z/)

      issue["body"].to_s[TICKET_MARKER, 1]&.upcase
    end

    def ambiguous_ticket_ids(issues_by_ticket)
      issues_by_ticket.select { |_ticket_id, issues| issues.length > 1 }.keys
    end

    def conflicting_manifest_mapping?(local_ticket, matches)
      return false unless local_ticket && local_ticket["github_issue"]

      mapped_number = local_ticket["github_issue"].to_i
      marked_numbers = matches.map { |issue| issue_number(issue) }
      marked_numbers.any? && !marked_numbers.include?(mapped_number) || marked_numbers.length > 1
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
        "title" => ticket["title"].to_s.empty? ? ticket.fetch("id") : ticket["title"].to_s,
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

    def project_item_fields(issue_number)
      item = Array(@remote["project_items"] || @remote[:project_items]).map { |entry| stringify_keys(entry) }.find do |entry|
        entry["issue_number"].to_i == issue_number.to_i
      end
      stringify_keys(item && item["fields"] || {})
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

    def stringify_keys(hash)
      hash.to_h { |key, value| [ key.to_s, value ] }
    end
  end
end
