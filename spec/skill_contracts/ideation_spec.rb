# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ideation skill contract" do
  SKILL_ROOT = Rails.root.join(".agents/skills/ideation")

  it "uses the isolated named Ideator and keeps ideation out of technical sources" do
    content = File.read(SKILL_ROOT.join("SKILL.md"))

    expect(content).to include("bootcamper_ideator")
    expect(content).to include("no inherited conversation")
    expect(content).to include("Do not read technical source files")
  end

  it "refreshes stale or changed research and cites its evidence" do
    content = File.read(SKILL_ROOT.join("SKILL.md"))

    expect(content).to include("older than 30 days")
    expect(content).to include("cited assumption changed")
    expect(content).to include("direct source links")
    expect(content).to include("verification dates")
  end

  it "deduplicates, scores, validates, and records the ideation outcome" do
    content = File.read(SKILL_ROOT.join("SKILL.md"))

    expect(content).to include("semantic comparison")
    expect(content).to include("User benefit")
    expect(content).to include("Progressiveness")
    expect(content).to include("Business value")
    expect(content).to include("Confidence")
    expect(content).to include("1 to 5")
    expect(content).to include("Validate each new IDEA version before updating its manifest")
    expect(content).to include("success")
    expect(content).to include("no-op")
    expect(content).to include("escalated")
    expect(content).to include("Never auto-approve an idea")
  end

  it "declares the requested interface and versioned IDEA format" do
    metadata = File.read(SKILL_ROOT.join("agents/openai.yaml"))
    format = File.read(SKILL_ROOT.join("references/idea-format.md"))

    expect(metadata).to include('display_name: "Ideation"')
    expect(metadata).to include('short_description: "Research and rank product ideas"')
    expect(metadata).to include('default_prompt: "Use $ideation to research Bootcamper and create versioned product ideas."')
    expect(format).to include("product/ideas/IDEA-NNN-short-slug/idea/vNNN.md")
    expect(format).to include("manifest.yml")
    expect(format).to include("changelog.md")
    expect(format).to include("research versions")
    expect(format).to include("factory run entry")
  end
end
