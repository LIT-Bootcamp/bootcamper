# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Idea analysis skill contract" do
  SKILL_ROOT = Rails.root.join(".agents/skills/idea-analyze")

  it "records the invoking human's approval only for a proposed IDEA" do
    content = File.read(SKILL_ROOT.join("SKILL.md"))

    expect(content).to include("explicit IDEA ID")
    expect(content).to include("proposed")
    expect(content).to include("reject")
    expect(content).to include("human-approved")
    expect(content).to include("analyzed")
  end

  it "publishes immutable IDEA versions for approval and completion before manifest changes" do
    content = File.read(SKILL_ROOT.join("SKILL.md"))

    expect(content).to include("idea/vNNN.md")
    expect(content).to include("immediate predecessor")
    expect(content).to include("run ID")
    expect(content).to include("non-empty reason")
    expect(content).to include("human-approved IDEA version")
    expect(content).to include("analyzed IDEA version")
    expect(content).to include("Validate the IDEA version before updating the manifest or changelog")
  end

  it "uses named isolated BA and Ideator clarification with a three-round limit" do
    content = File.read(SKILL_ROOT.join("SKILL.md"))

    expect(content).to include("bootcamper_business_analyst")
    expect(content).to include("bootcamper_ideator")
    expect(content).to include("isolated context")
    expect(content).to include("no inherited conversation")
    expect(content).to include("at most three clarification rounds")
    expect(content).to include("clarification-protocol.md")
    expect(content).to include("analysis/")
  end

  it "keeps every EPIC, Gherkin, and coverage edit under BA ownership" do
    content = File.read(SKILL_ROOT.join("SKILL.md"))

    expect(content).to include("BA alone")
    expect(content).to include("stable EPIC")
    expect(content).to include("one Gherkin document per EPIC")
    expect(content).to include("coverage.yml")
    expect(content).to include("bin/product_factory validate --root product")
  end

  it "declares complete requirement-to-scenario coverage and escalation preservation" do
    content = File.read(SKILL_ROOT.join("SKILL.md"))
    format = File.read(SKILL_ROOT.join("references/epic-and-gherkin-format.md"))

    expect(content).to include("happy-path")
    expect(content).to include("edge or error")
    expect(content).to include("third unresolved round")
    expect(content).to include("last valid state")
    expect(format).to include("product/ideas/IDEA-NNN-short-slug/epics/EPIC-NNN-short-slug/requirements/vNNN.feature")
    expect(format).to include("coverage.yml")
    expect(format).to include("requirement_id")
    expect(format).to include("happy_path")
    expect(format).to include("edge_or_error")
  end

  it "declares the requested interface" do
    metadata = File.read(SKILL_ROOT.join("agents/openai.yaml"))

    expect(metadata).to include('display_name: "Analyze Product Idea"')
    expect(metadata).to include('short_description: "Turn one approved idea into Gherkin epics"')
    expect(metadata).to include('default_prompt: "Use $idea-analyze with an IDEA ID to approve and analyze that product idea."')
  end
end
