# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product factory agent contracts" do
  AGENTS = {
    "bootcamper-ideator.toml" => {
      name: "bootcamper_ideator",
      sandbox: "read-only",
      ownership: "Own IDEA artifacts",
      prohibited: "Do not inspect application code",
      escalation: "Escalate when an uncertainty materially changes product behavior, security, cost, or an external commitment"
    },
    "bootcamper-business-analyst.toml" => {
      name: "bootcamper_business_analyst",
      sandbox: "read-only",
      ownership: "Own EPIC boundaries, Gherkin, and coverage artifacts",
      prohibited: "Do not write TICKET artifacts",
      escalation: "Escalate when an uncertainty materially changes product behavior, security, cost, or an external commitment"
    },
    "bootcamper-technical-lead.toml" => {
      name: "bootcamper_technical_lead",
      sandbox: "read-only",
      ownership: "Own TICKET and dependency graph artifacts",
      prohibited: "Do not edit BA-owned artifacts",
      escalation: "Escalate when an uncertainty materially changes product behavior, security, cost, or an external commitment"
    },
    "bootcamper-backlogger.toml" => {
      name: "bootcamper_backlogger",
      sandbox: "workspace-write",
      ownership: "Own GitHub Issue projection and TICKET-ID to GitHub Issue ID mapping artifacts",
      prohibited: "Do not change business requirements or technical scope",
      escalation: "Escalate when an uncertainty materially changes product behavior, security, cost, or an external commitment"
    }
  }.freeze

  AGENT_ROOT = Rails.root.join(".codex/agents")
  HANDOFF_HEADER = <<~YAML.freeze
    status: success | no-op | escalated
    run_id: RUN-...
    input_versions: {}
    output_paths: []
    assumptions: []
    unresolved_questions: []
  YAML

  it "declares unique, bounded product-analysis agents" do
    names = AGENTS.map do |path, contract|
      content = File.read(AGENT_ROOT.join(path))

      expect(content).to include("name = \"#{contract[:name]}\"")
      expect(content).to include('model_reasoning_effort = "high"')
      expect(content).to include("sandbox_mode = \"#{contract[:sandbox]}\"")
      expect(content).to include(contract[:ownership])
      expect(content).to include("Each artifact version is immutable")
      expect(content).to include(contract[:escalation])
      expect(content).to include(contract[:prohibited])
      expect(content).to include(HANDOFF_HEADER)

      contract[:name]
    end

    expect(names).to eq(names.uniq)
  end

  it "limits Backlogger GitHub access to the explicitly authorized backlog target" do
    content = File.read(AGENT_ROOT.join("bootcamper-backlogger.toml"))

    expect(content).to include("Only call GitHub when backlog-idea explicitly authorizes the exact Project and repository")
  end

  it "limits BA edits to BA-owned artifacts" do
    content = File.read(AGENT_ROOT.join("bootcamper-business-analyst.toml"))

    expect(content).to include("Only edit BA-owned EPIC, Gherkin, and coverage artifacts")
    expect(content).to include("Do not edit IDEA artifacts")
  end

  it "defines bounded, owner-only clarification rounds" do
    content = File.read(Rails.root.join("docs/product-factory/clarification-protocol.md"))

    expect(content).to include("maximum of three rounds")
    expect(content).to include("numbered questions")
    expect(content).to include("direct answers")
    expect(content).to include("resolved")
    expect(content).to include("open")
    expect(content).to include("assumptions")
    expect(content).to include("Only the artifact owner edits its artifact")
    expect(content).to include("new immutable version")
    expect(content).to include("next sequential version")
    expect(content).to include("Validate the new version before updating its manifest")
    expect(content).to match(/current_version.*content_sha256.*only after validation/)
    expect(content).to include("retain its immediate predecessor")
    expect(content).to include("escalation packet")
  end
end
