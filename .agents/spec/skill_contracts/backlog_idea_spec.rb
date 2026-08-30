# frozen_string_literal: true

require "pathname"

# rubocop:disable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe "Backlog reconciliation skill contract" do
  let(:skill_root) { Pathname(__dir__).join("../../skills/backlog-idea").expand_path }

  it "builds a deterministic preview with the pure planner before any mutation" do
    content = File.read(skill_root.join("SKILL.md"))

    expect(content).to include("bootcamper_backlogger")
    expect(content).to include("isolated context")
    expect(content).to include("bin/product_factory validate --root product")
    expect(content).to include("ProductFactory::GitHubPlan")
    expect(content).to include("deterministic preview")
    expect(content).to include("Preview and apply are separate")
    expect(content).to include("explicit human authorization")
  end

  it "uses stable ticket markers and handles every reconciliation outcome" do
    content = File.read(skill_root.join("SKILL.md"))
    procedure = File.read(skill_root.join("references/github-reconciliation.md"))

    expect(content).to include("product-factory-ticket-id")
    expect(content).to include("create", "update", "close superseded", "reopen", "no-op")
    expect(content).to include("active branch or pull request")
    expect(content).to include("merged pull request")
    expect(content).to include("ambiguous")
    expect(procedure).to include("gh issue create")
    expect(procedure).to include("gh issue edit")
    expect(procedure).to include("gh issue close")
    expect(procedure).to include("gh issue reopen")
    expect(procedure).to include("gh project item-add")
    expect(procedure).to include("gh project item-edit")
    expect(procedure).to include("--limit 1000")
    expect(procedure).to include("Immediately before apply")
    expect(procedure).to include("Compare their hashes")
    expect(procedure).to include("local projection digest")
    expect(procedure).to include("repository base commit")
  end

  it "requires project authorization and configures the complete managed field set" do
    content = File.read(skill_root.join("SKILL.md"))
    procedure = File.read(skill_root.join("references/github-reconciliation.md"))

    expect(procedure).to include("gh auth status")
    expect(procedure).to include("project scope")
    expect(procedure).to include("one field per invocation")
    expect(procedure).to include("journal entry")
    expect(procedure).to include("explicit Project-add operation")
    expect(procedure).to include("gh api graphql")
    expect(procedure).to include("dataType")
    expect(procedure).to include("ProjectV2SingleSelectField")
    expect(procedure).to include("totalCount")
    expect(procedure).to include("hasNextPage")
    expect(procedure).to include("gh project field-create")
    expect(procedure).to include("project_field_update")
    expect(procedure).to include("built-in `Status`")
    expect(procedure).to include("duplicate managed field names")
    expect(procedure).to include("incompatible type")
    expect(content).to include(
      "Idea", "Epic", "Ticket ID", "Priority", "Status", "Estimate", "Dependencies",
      "Source Version", "Factory Run"
    )
  end

  it "declares the requested interface" do
    metadata = File.read(skill_root.join("agents/openai.yaml"))

    expect(metadata).to include('display_name: "Reconcile Product Backlog"')
    expect(metadata).to include('short_description: "Sync changed factory tickets to GitHub"')
    expect(metadata).to include('default_prompt: "Use $backlog-idea to incrementally reconcile product tickets with the Bootcamper GitHub Project."')
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
