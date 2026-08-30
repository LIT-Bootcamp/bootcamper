# frozen_string_literal: true

require "rails_helper"

# Contract specs intentionally assert several independent required phrases.
# rubocop:disable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe "Documentation analysis skill contract" do
  let(:skill_root) { Rails.root.join(".agents/skills/documentation-analyze") }

  it "incrementally scans every BA-ready EPIC with an optional IDEA filter" do
    content = File.read(skill_root.join("SKILL.md"))

    expect(content).to include("all IDEA directories")
    expect(content).to include("new or changed `BA-ready` EPIC versions")
    expect(content).to include("optional IDEA ID")
    expect(content).to include("does not change the incremental comparison")
    expect(content).to include("success", "no-op", "escalated")
  end

  it "uses the three-round TL-to-BA protocol without editing BA artifacts" do
    content = File.read(skill_root.join("SKILL.md"))

    expect(content).to include("bootcamper_technical_lead")
    expect(content).to include("bootcamper_business_analyst")
    expect(content).to include("isolated context")
    expect(content).to include("no inherited conversation")
    expect(content).to include("at most three clarification rounds")
    expect(content).to include("BA alone")
    expect(content).to include("must not edit BA-owned")
    expect(content).to include("third unresolved round")
  end

  it "produces traceable bounded tickets and acyclic delivery planning" do
    content = File.read(skill_root.join("SKILL.md"))
    format = File.read(skill_root.join("references/ticket-format.md"))

    expect(content).to include("exact scenario IDs or lines")
    expect(content).to include("difficulty from 1 to 5")
    expect(content).to include("at most 2 ideal days")
    expect(content).to include("acyclic")
    expect(content).to include("delivery waves")
    expect(content).to include("independent EPICs")
    expect(format).to include("Observable goal")
    expect(format).to include("Source IDEA, EPIC, version, and scenario IDs")
    expect(format).to include("Acceptance evidence")
    expect(format).to include("Dependencies")
    expect(format).to include("Difficulty (1-5)")
    expect(format).to include("Estimate (ideal days, at most 2)")
    expect(format).to include("Risks")
    expect(format).to include("External actions")
    expect(format).to include("Allowed scope")
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
