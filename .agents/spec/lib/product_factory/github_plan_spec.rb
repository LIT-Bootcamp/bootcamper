# frozen_string_literal: true

require_relative "../../../../lib/product_factory/github_plan"

# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe ProductFactory::GitHubPlan do
  MARKER = "<!-- product-factory-ticket-id: TICKET-001 -->"

  def ticket(id: "TICKET-001", **overrides)
    {
      "id" => id,
      "title" => "Add course catalog",
      "body" => "Deliver the observable catalog outcome.",
      "state" => "available",
      "github_issue" => nil,
      "idea_id" => "IDEA-001",
      "epic_id" => "EPIC-001",
      "priority" => 1,
      "estimate_days" => 1.5,
      "dependencies" => [],
      "current_version" => 2,
      "factory_run" => "RUN-20260830T120000Z-a1b2c3"
    }.merge(overrides.transform_keys(&:to_s))
  end

  def issue(number: 42, state: "OPEN", title: "Add course catalog", body: "Deliver the observable catalog outcome.\n\n#{MARKER}", **overrides)
    {
      "number" => number,
      "state" => state,
      "title" => title,
      "body" => body,
      "labels" => [ "manual-label" ],
      "assignees" => [ "human" ]
    }.merge(overrides.transform_keys(&:to_s))
  end

  def project_fields
    ProductFactory::GitHubPlan::PROJECT_FIELD_TYPES.map do |name, data_type|
      field = { "name" => name, "data_type" => data_type }
      field["options"] = ProductFactory::GitHubPlan::STATUS_OPTIONS if name == "Status"
      field
    end
  end

  def remote(issues: [], project_items: [], pull_requests: [], branches: [], project_fields: self.project_fields)
    {
      "issues" => issues,
      "project_items" => project_items,
      "pull_requests" => pull_requests,
      "branches" => branches,
      "project_fields" => project_fields
    }
  end

  def plan(local, remote_state)
    described_class.new(local: local, remote: remote_state).operations
  end

  it "creates an issue and deterministic project field updates for a new ticket" do
    operations = plan({ "TICKET-001" => ticket }, remote)

    expect(operations.first).to have_attributes(
      action: :create,
      ticket_id: "TICKET-001",
      issue_number: nil
    )
    expect(operations.first.attributes).to include(
      "title" => "Add course catalog",
      "body" => include(MARKER)
    )
    expect(operations).to include(have_attributes(action: :project_add, ticket_id: "TICKET-001", issue_number: nil))
    expect(operations.select { |operation| operation.action == :project_field }.map { |operation| operation.attributes.fetch("field") }).to contain_exactly(
      "Idea", "Epic", "Ticket ID", "Priority", "Status", "Estimate", "Dependencies", "Source Version", "Factory Run"
    )
  end

  it "previews creation of every missing GitHub Project field" do
    operations = plan({}, remote(project_fields: []))

    schema = operations.select { |operation| operation.action == :project_field_create }
    expect(schema.map { |operation| operation.attributes.fetch("field") }).to contain_exactly(
      "Idea", "Epic", "Ticket ID", "Priority", "Status", "Estimate", "Dependencies", "Source Version", "Factory Run"
    )
    expect(schema.find { |operation| operation.attributes["field"] == "Status" }.attributes).to include(
      "data_type" => "SINGLE_SELECT",
      "options" => ProductFactory::GitHubPlan::STATUS_OPTIONS
    )
  end

  it "escalates an incompatible same-name GitHub Project field" do
    fields = project_fields.map(&:dup)
    fields.find { |field| field["name"] == "Priority" }["data_type"] = "TEXT"

    expect(plan({}, remote(project_fields: fields))).to eq([
      ProductFactory::GitHubOperation.new(:escalate, nil, nil, {
        "reason" => "incompatible GitHub Project field",
        "field" => "Priority",
        "expected_type" => "NUMBER"
      })
    ])
  end

  it "updates Git-authoritative issue content and changed managed project fields" do
    local = { "TICKET-001" => ticket(github_issue: 42, priority: 1) }
    remote_state = remote(
      issues: [ issue(title: "Manual title", body: "Manual body\n\n#{MARKER}") ],
      project_items: [ { "issue_number" => 42, "fields" => { "Priority" => "3", "Status" => "available" } } ]
    )

    operations = plan(local, remote_state)

    expect(operations).to include(have_attributes(action: :update, ticket_id: "TICKET-001", issue_number: 42))
    expect(operations).to include(have_attributes(action: :project_field, attributes: include("field" => "Priority", "value" => "1")))
  end

  it "closes a remote issue as superseded when its ticket disappeared" do
    operations = plan({}, remote(issues: [ issue ]))

    expect(operations).to eq([
      ProductFactory::GitHubOperation.new(:close_superseded, "TICKET-001", 42, { "reason" => "ticket absent from canonical Git artifacts" })
    ])
  end

  it "reopens a closed issue for a canonical active ticket" do
    operations = plan({ "TICKET-001" => ticket(github_issue: 42) }, remote(issues: [ issue(state: "CLOSED") ]))

    expect(operations).to include(have_attributes(action: :reopen, ticket_id: "TICKET-001", issue_number: 42))
  end

  it "adds an existing mapped issue to the Project before field updates" do
    operations = plan({ "TICKET-001" => ticket(github_issue: 42) }, remote(issues: [ issue ]))

    expect(operations).to include(have_attributes(action: :project_add, ticket_id: "TICKET-001", issue_number: 42))
    expect(operations).to include(have_attributes(action: :project_field, ticket_id: "TICKET-001", issue_number: 42))
  end

  it "returns no operations when managed content is unchanged and ignores unmanaged manual drift" do
    fields = {
      "Idea" => "IDEA-001", "Epic" => "EPIC-001", "Ticket ID" => "TICKET-001", "Priority" => "1",
      "Status" => "available", "Estimate" => "1.5", "Dependencies" => "", "Source Version" => "2",
      "Factory Run" => "RUN-20260830T120000Z-a1b2c3", "Manual Notes" => "keep this"
    }
    remote_state = remote(issues: [ issue ], project_items: [ { "issue_number" => 42, "fields" => fields } ])

    expect(plan({ "TICKET-001" => ticket(github_issue: 42) }, remote_state)).to be_empty
  end

  it "escalates duplicate or conflicting stable-ID mappings" do
    duplicate = issue(number: 43)
    operations = plan({ "TICKET-001" => ticket(github_issue: 42) }, remote(issues: [ issue, duplicate ]))

    expect(operations).to eq([
      ProductFactory::GitHubOperation.new(:escalate, "TICKET-001", nil, {
        "reason" => "ambiguous stable Ticket ID mapping",
        "issue_numbers" => [ 42, 43 ]
      })
    ])
  end

  it "escalates when one issue contains conflicting markers" do
    conflicting = issue(body: "#{MARKER}\n<!-- product-factory-ticket-id: TICKET-002 -->")
    operations = plan(
      { "TICKET-001" => ticket(github_issue: 42), "TICKET-002" => ticket(id: "TICKET-002") },
      remote(issues: [ conflicting ])
    )

    expect(operations.select { |operation| operation.action == :escalate }.map(&:ticket_id)).to contain_exactly("TICKET-001", "TICKET-002")
  end

  it "escalates remote-only conflicting and repeated markers" do
    conflicting = issue(body: "#{MARKER}\n<!-- product-factory-ticket-id: TICKET-002 -->")
    repeated = issue(number: 43, body: "#{MARKER}\n#{MARKER}")

    operations = plan({}, remote(issues: [ conflicting, repeated ]))

    expect(operations.select { |operation| operation.action == :escalate }.map(&:ticket_id)).to contain_exactly("TICKET-001", "TICKET-002")
    expect(operations.find { |operation| operation.ticket_id == "TICKET-001" }.attributes.fetch("issue_numbers")).to contain_exactly(42, 43)
  end

  it "escalates when an explicit remote ID disagrees with the body marker" do
    conflicting = issue(ticket_id: "TICKET-002")
    operations = plan(
      { "TICKET-001" => ticket(github_issue: 42), "TICKET-002" => ticket(id: "TICKET-002") },
      remote(issues: [ conflicting ])
    )

    expect(operations.select { |operation| operation.action == :escalate }.map(&:ticket_id)).to contain_exactly("TICKET-001", "TICKET-002")
  end

  it "escalates when local manifests claim the same GitHub issue" do
    operations = plan(
      {
        "TICKET-001" => ticket(github_issue: 42),
        "TICKET-002" => ticket(id: "TICKET-002", github_issue: 42)
      },
      remote(issues: [ issue ])
    )

    expect(operations.select { |operation| operation.action == :escalate }.map(&:ticket_id)).to contain_exactly("TICKET-001", "TICKET-002")
  end

  it "does not erase GitHub content when canonical projection values are missing" do
    incomplete = ticket(github_issue: 42)
    incomplete.delete("title")
    incomplete.delete("body")

    operations = plan({ "TICKET-001" => incomplete }, remote(issues: [ issue ]))

    expect(operations).to eq([
      ProductFactory::GitHubOperation.new(:escalate, "TICKET-001", 42, {
        "reason" => "canonical ticket projection is incomplete",
        "missing_fields" => [ "title", "body" ]
      })
    ])
  end

  it "escalates instead of closing when a branch or pull request protects implementation work" do
    operations = plan({}, remote(
      issues: [ issue ],
      branches: [ { "ticket_id" => "TICKET-001", "name" => "feat/TICKET-001-catalog" } ]
    ))

    expect(operations).to eq([
      ProductFactory::GitHubOperation.new(:escalate, "TICKET-001", 42, {
        "reason" => "active branch or pull request protects ticket from closure"
      })
    ])
  end

  it "marks the canonical ticket complete when its pull request merged" do
    operations = plan(
      { "TICKET-001" => ticket(github_issue: 42, state: "ready-for-human-merge") },
      remote(
        issues: [ issue ],
        pull_requests: [ { "ticket_id" => "TICKET-001", "number" => 77, "state" => "MERGED" } ]
      )
    )

    expect(operations).to include(
      ProductFactory::GitHubOperation.new(:complete_merged, "TICKET-001", 42, { "pull_request" => 77, "state" => "done" })
    )
  end

  it "sorts operations stably by Ticket ID and action" do
    local = {
      "TICKET-010" => ticket(id: "TICKET-010", title: "Later"),
      "TICKET-002" => ticket(id: "TICKET-002", title: "Earlier")
    }

    operations = plan(local, remote)
    keys = operations.map { |operation| [ operation.ticket_id, operation.action.to_s, operation.attributes["field"].to_s ] }

    expect(keys).to eq(keys.sort)
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
