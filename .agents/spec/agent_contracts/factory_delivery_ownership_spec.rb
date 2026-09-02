# frozen_string_literal: true

require "pathname"
require "spec_helper"

RSpec.describe "Product factory delivery ownership" do
  let(:root) { Pathname(__dir__).join("../../..").expand_path }

  it "makes Lead publish the pre-merge artifact and CI own post-merge completion" do
    lead = File.read(root.join(".codex/agents/lead-bootcamper.toml"))
    backlogger = File.read(root.join(".codex/agents/bootcamper-backlogger.toml"))

    expect(lead).to include("same PR branch", "post-merge GitHub Actions reconciler")
    expect(backlogger).to include("post-merge CI reconciler owns the primary Git lifecycle transition")
    expect(backlogger).to include("never create a duplicate `done` version")
  end

  it "requires every audit violation to name its responsible component" do
    skill = File.read(root.join(".agents/skills/control-bootcamper-delivery/SKILL.md"))
    controller = File.read(root.join(".codex/agents/bootcamper-delivery-controller.toml"))

    expect(skill).to include("responsible_component")
    expect(controller).to include("responsible_component")
    expect(controller).to include("Never use passive labels")
  end
end
