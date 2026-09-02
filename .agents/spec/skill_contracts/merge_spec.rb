# frozen_string_literal: true

require "pathname"
require "spec_helper"

RSpec.describe "Product factory merge skill contract" do
  let(:skill_root) { Pathname(__dir__).join("../../skills/merge").expand_path }

  it "keeps merge human-triggered and makes CI own Git-first completion" do
    content = File.read(skill_root.join("SKILL.md"))

    expect(content).to include("explicit-only")
    expect(content).to include("Only the project-scoped `lead_bootcamper` agent may execute")
    expect(content).to include("post-merge CI reconciler")
    expect(content).to include("canonical Git")
    expect(content).to include("before GitHub Project")
    expect(content).to include("idempotently")
    expect(content).to include("must fail visibly")
  end

  it "is discoverable only through explicit invocation" do
    metadata = File.read(skill_root.join("agents/openai.yaml"))

    expect(metadata).to include('default_prompt: "$merge <PR-number>"')
    expect(metadata).to include("allow_implicit_invocation: false")
  end
end
