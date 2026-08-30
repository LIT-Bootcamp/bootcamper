# frozen_string_literal: true

require "rails_helper"

# Contract specs intentionally assert several independent required phrases.
# rubocop:disable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe "Product factory implementation skill contract" do
  let(:skill_root) { Rails.root.join(".agents/skills/implement") }

  it "selects and claims exactly one priority and dependency-safe ticket before isolation" do
    content = File.read(skill_root.join("SKILL.md"))
    selection = File.read(skill_root.join("references/ticket-selection.md"))

    expect(content).to include("bin/product_factory validate --root product")
    expect(content).to include("bin/product_factory start-run --root product --phase implement")
    expect(content).to include("bin/product_factory next-ticket --root product --run-id")
    expect(content).to include("exactly one ticket per invocation")
    expect(content).to include("claim before creating a branch or worktree")
    expect(content).to include("bin/product_factory move-run")
    expect(selection).to include("highest-priority")
    expect(selection).to include("dependencies are satisfied")
    expect(selection).to include("shared Git common directory")
    expect(selection).to include("claim lock")
    expect(selection).to include("separate ticket branch and worktree")
  end

  it "publishes lifecycle versions and delegates factory delivery to named isolated agents" do
    content = File.read(skill_root.join("SKILL.md"))

    expect(content).to include("new immutable ticket version")
    expect(content).to include("temporary product-tree copy")
    expect(content).to include("in-progress")
    expect(content).to include("deliver-rails-ticket")
    expect(content).to include("factory_mode: true")
    expect(content).to include("senior_ruby_rails_engineer")
    expect(content).to include("fresh_eye_rails_reviewer")
    expect(content).to include("project_context_rails_reviewer")
    expect(content).to include("three remediation rounds")
    expect(content).to include("ready-for-human-merge")
  end

  it "releases claims on every terminal path without destroying failed worktrees" do
    content = File.read(skill_root.join("SKILL.md"))
    selection = File.read(skill_root.join("references/ticket-selection.md"))

    expect(content).to include("bin/product_factory release-ticket")
    expect(content).to include("success or failure")
    expect(content).to include("Do not use destructive cleanup")
    expect(content).to include("Preserve a failed worktree")
    expect(content).to include("exact recovery instructions")
    expect(content).to include("worktree path")
    expect(selection).to include("release the transient claim")
    expect(selection).to include("escalated")
  end

  it "does not merge and records no-op when no ticket is available" do
    content = File.read(skill_root.join("SKILL.md"))

    expect(content).to include("exit status 3")
    expect(content).to include("no-op")
    expect(content).to include("human-only merge")
    expect(content).to include("Never merge automatically")
    expect(content).to include("success", "no-op", "escalated")
  end

  it "declares the requested interface" do
    metadata = File.read(skill_root.join("agents/openai.yaml"))

    expect(metadata).to include('display_name: "Implement Next Product Ticket"')
    expect(metadata).to include('short_description: "Deliver the next ready ticket to a reviewed PR"')
    expect(metadata).to include(
      'default_prompt: "Use $implement to claim and deliver the highest-priority available product ticket."'
    )
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
