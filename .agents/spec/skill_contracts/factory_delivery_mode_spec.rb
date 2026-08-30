# frozen_string_literal: true

require "rails_helper"

# Contract specs intentionally assert several independent required phrases.
# rubocop:disable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe "Factory delivery mode skill contract" do
  let(:implement_root) { Rails.root.join(".agents/skills/implement-rails-ticket") }
  let(:deliver_root) { Rails.root.join(".agents/skills/deliver-rails-ticket") }

  it "preserves explicit ticket selection and exact-plan approval in ordinary mode" do
    skill = File.read(implement_root.join("SKILL.md"))
    preflight = File.read(implement_root.join("references/preflight-and-approval.md"))

    expect(skill).to include("The user explicitly selects a stable ticket identifier")
    expect(skill).to include("The user approves that exact plan")
    expect(preflight).to include("If the user supplies work without a stable ID")
    expect(preflight).to include("Ask the user to approve execution of that exact plan")
    expect(preflight).to include("Any material revision requires fresh approval")
  end

  it "requires approved lineage, dependency safety, and an active claim in factory mode" do
    skill = File.read(implement_root.join("SKILL.md"))
    preflight = File.read(implement_root.join("references/preflight-and-approval.md"))

    expect(skill).to include("## Factory Mode")
    expect(skill).to include("factory_mode: true")
    expect(skill).to include("ticket_state: in-progress")
    expect(skill).to include("claim_run_id: RUN-...")
    expect(skill).to include("idea_state: analyzed")
    expect(skill).to include("epic_state: TL-approved")
    expect(skill).to include("dependencies_satisfied: true")
    expect(skill).to include("active claim")
    expect(preflight).to include("approved IDEA lineage")
  end

  it "uses the immutable ticket version as factory approval without weakening scope gates" do
    skill = File.read(implement_root.join("SKILL.md"))
    preflight = File.read(implement_root.join("references/preflight-and-approval.md"))

    expect(skill).to include("immutable ticket version")
    expect(skill).to include("approved scope boundary")
    expect(skill).to include("does not select backlog work")
    expect(skill).to include("must not expand ticket scope")
    expect(skill).to include("unanswered consequential question")
    expect(preflight).to include("skip per-ticket plan approval")
    expect(preflight).to include("material evidence")
  end

  it "preserves dual review, remediation, and lead-only release in factory mode" do
    skill = File.read(deliver_root.join("SKILL.md"))
    close = File.read(deliver_root.join("references/review-and-close.md"))

    expect(skill).to include("two isolated reviewer agents")
    expect(skill).to include("Factory Mode")
    expect(skill).to include("must not skip dual review")
    expect(skill).to include("lead_bootcamper")
    expect(close).to include("same remediation")
    expect(close).to include("lead-only")
  end

  it "stops factory delivery at ready-for-human-merge and reserves merge for a human" do
    skill = File.read(deliver_root.join("SKILL.md"))
    close = File.read(deliver_root.join("references/review-and-close.md"))

    expect(skill).to include("ready-for-human-merge")
    expect(skill).to include("Only a human may merge")
    expect(skill).not_to include("merge after human review/explicit `skip review`")
    expect(close).to include("commit, push, and open the pull request")
    expect(close).to include("must not merge")
    expect(close).to include("ticket state to `ready-for-human-merge`")
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/ExampleLength, RSpec/MultipleExpectations
