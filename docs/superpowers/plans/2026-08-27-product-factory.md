# Product Factory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build five incremental skills and four product agents that turn versioned product ideas into human-merge-ready pull requests.

**Architecture:** Git-tracked Markdown, Gherkin, and YAML files hold canonical factory state. A small Ruby CLI validates artifacts, computes changes, maintains run checkpoints, and coordinates local ticket claims; skills own agent orchestration and GitHub reconciliation. Existing Rails implementation, review, and lead-release workflows gain a narrow factory mode instead of being duplicated.

**Tech Stack:** Codex project skills and custom-agent TOML, Ruby standard library, YAML, SHA-256, RSpec, Git, GitHub CLI

**Spec:** `docs/superpowers/specs/2026-08-27-product-factory-design.md`

## Global Constraints

- Git files are the source of truth; one GitHub Project is a projection.
- Store every artifact version as an immutable physical file with a reason for change.
- Use English for IDEA, EPIC, Gherkin, TICKET, and log content.
- Process only new, changed, deleted, or newly unblocked artifacts; unchanged reruns return `no-op`.
- A ticket estimate cannot exceed two ideal engineering days.
- `idea-analyze IDEA-ID` records human approval; no later product-analysis approval gate exists.
- Backlogger may mutate GitHub Issues and Project fields but must escalate ambiguous mappings or active-work deletion.
- `implement` selects one highest-priority available ticket and stops at `ready-for-human-merge`.
- Only a human may authorize merge.
- Use no new gem, database, daemon, scheduler, dashboard, or workflow engine.
- Preserve unrelated working-tree changes.

---

### Task 1: Add the artifact contract and deterministic factory CLI

**Files:**
- Create: `docs/product-factory/artifact-contract.md`
- Create: `lib/product_factory.rb`
- Create: `bin/product_factory`
- Create: `.agents/spec/lib/product_factory_spec.rb`
- Create: `product/factory-log/.gitkeep`
- Create: `product/research/.gitkeep`
- Create: `product/ideas/.gitkeep`

**Interfaces:**
- Consumes: files below `product/ideas/` and `product/factory-log/`
- Produces: `ProductFactory::Repository`, `ProductFactory::Validator`, `ProductFactory::Run`, `ProductFactory::ClaimRegistry`; CLI commands `validate`, `changes`, `start-run`, `finish-run`, `next-ticket`, and `release-ticket`

- [ ] **Step 1: Write the artifact contract**

Document exact directory names, stable ID patterns, lifecycle transitions, required YAML keys, version ancestry, SHA-256 calculation, coverage rows, dependency rows, run-log fields, and GitHub mapping fields. Use these canonical shapes:

```yaml
# manifest.yml
id: TICKET-001
kind: ticket
current_version: 2
state: available
source_versions:
  EPIC-001: 3
content_sha256: <64 lowercase hex characters>
github_issue: 42
dependencies: [TICKET-000]
priority: 1
estimate_days: 1.5
```

```yaml
# version front matter
id: TICKET-001
version: 2
author: technical_lead
run_id: RUN-20260827T120000Z-a1b2c3
created_at: '2026-08-27T12:00:00Z'
previous_version: 1
reason: Split delivery from review after dependency analysis
source_versions:
  EPIC-001: 3
assumptions: []
unresolved_questions: []
```

Allow only the lifecycle transitions in the design spec. Define `content_sha256` as SHA-256 of the version file bytes after normalizing CRLF to LF.

- [ ] **Step 2: Write failing CLI and validation specs**

Use temporary directories. Cover:

```ruby
RSpec.describe ProductFactory::Validator do
  it "accepts a valid immutable version chain"
  it "rejects a missing reason for change"
  it "rejects a content hash mismatch"
  it "rejects an illegal lifecycle transition"
  it "rejects a dependency cycle"
  it "rejects a ticket over two ideal days"
  it "rejects uncovered scenarios and orphan tickets"
end

RSpec.describe ProductFactory::Repository do
  it "reports new, changed, deleted, newly unblocked, and unchanged IDs"
  it "returns no actionable IDs after an unchanged successful run"
  it "selects priority before ID among available dependency-safe tickets"
end

RSpec.describe ProductFactory::ClaimRegistry do
  it "allows only one process to claim a ticket"
  it "releases a claim owned by the matching run"
end
```

- [ ] **Step 3: Run the specs and confirm the expected failure**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/lib/product_factory_spec.rb`

Expected: FAIL because `ProductFactory` and the CLI do not exist.

- [ ] **Step 4: Implement the minimum Ruby library**

Use only `yaml`, `json`, `digest`, `time`, `pathname`, `securerandom`, `open3`, and `fileutils`. Public signatures:

```ruby
module ProductFactory
  Change = Data.define(:id, :kind, :status, :current_version, :previous_version)

  class Repository
    def initialize(root:) = @root = Pathname(root)
    def validate! = Validator.new(root: @root).validate!
    def changes(phase:) = [] # return Array<Change>
    def next_ticket = nil    # return ticket manifest path or nil
  end

  class Run
    def self.start(root:, phase:, source_ids:) = new(...)
    def finish!(status:, output_ids:, external_changes: [], error: nil) = nil
  end

  class ClaimRegistry
    def initialize(git_common_dir:) = @root = Pathname(git_common_dir).join("product-factory")
    def claim!(ticket_id:, run_id:) = nil
    def release!(ticket_id:, run_id:) = nil
  end
end
```

Resolve the shared claim directory with `git rev-parse --git-common-dir`. Guard read-check-write with `File.flock(File::LOCK_EX)`. Store one small YAML claim file per ticket under the Git common directory; never store credentials there.

- [ ] **Step 5: Add the executable CLI**

`bin/product_factory` must parse commands with `OptionParser`, print JSON on stdout, write errors on stderr, and return exit codes `0` success, `2` validation failure, `3` no actionable item, and `4` claim conflict. Require explicit `--root`, `--phase`, `--run-id`, and `--ticket` where the command needs them.

- [ ] **Step 6: Run focused verification**

Run:

```bash
mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/lib/product_factory_spec.rb
bin/product_factory validate --root product
git diff --check
```

Expected: all specs pass, validation succeeds on the empty scaffold, and `git diff --check` prints nothing.

- [ ] **Step 7: Commit through the lead workflow**

```bash
git add docs/product-factory/artifact-contract.md lib/product_factory.rb bin/product_factory .agents/spec/lib/product_factory_spec.rb product
bin/lead_bootcamper commit -m "feat: add product factory contracts"
```

### Task 2: Add product-analysis custom agents and shared clarification protocol

**Files:**
- Create: `.codex/agents/bootcamper-ideator.toml`
- Create: `.codex/agents/bootcamper-business-analyst.toml`
- Create: `.codex/agents/bootcamper-technical-lead.toml`
- Create: `.codex/agents/bootcamper-backlogger.toml`
- Create: `docs/product-factory/clarification-protocol.md`
- Create: `.agents/spec/agent_contracts/product_factory_agents_spec.rb`

**Interfaces:**
- Consumes: artifact contract from Task 1
- Produces: named agents `bootcamper_ideator`, `bootcamper_business_analyst`, `bootcamper_technical_lead`, and `bootcamper_backlogger`; clarification rounds with `questions`, `answers`, `resolved`, `open`, and `assumptions`

- [ ] **Step 1: Write failing contract specs**

Parse TOML as text because Ruby has no installed TOML parser. Assert each file has a unique `name`, `model_reasoning_effort = "high"`, its ownership boundary, immutable-version rule, escalation boundary, and prohibited actions. Assert Ideator cannot inspect application code, BA cannot write tickets, TL cannot edit BA artifacts, and Backlogger cannot change requirements.

- [ ] **Step 2: Run the specs and confirm missing files fail**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/agent_contracts/product_factory_agents_spec.rb`

Expected: FAIL with missing agent contract paths.

- [ ] **Step 3: Create the four agent contracts**

Give each agent `model_reasoning_effort = "high"`. Use read-only sandbox for Ideator, BA, and TL. Backlogger needs workspace access for version and mapping files but may call GitHub only when `backlog-idea` explicitly authorizes the exact Project and repository.

Each agent returns a machine-checkable handoff header:

```yaml
status: success | no-op | escalated
run_id: RUN-...
input_versions: {}
output_paths: []
assumptions: []
unresolved_questions: []
```

- [ ] **Step 4: Write the clarification protocol**

Define three-round maximum, numbered questions, direct answers, resolved/open sets, owner-only artifact edits, version bump requirements, and the escalation packet. Do not create a `communicate` skill.

- [ ] **Step 5: Run focused verification**

Run:

```bash
mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/agent_contracts/product_factory_agents_spec.rb
git diff --check
```

Expected: PASS and no whitespace errors.

- [ ] **Step 6: Commit through the lead workflow**

```bash
git add .codex/agents/bootcamper-*.toml docs/product-factory/clarification-protocol.md .agents/spec/agent_contracts/product_factory_agents_spec.rb
bin/lead_bootcamper commit -m "feat: add product factory agents"
```

### Task 3: Add the `ideation` skill

**Files:**
- Create: `.agents/skills/ideation/SKILL.md`
- Create: `.agents/skills/ideation/agents/openai.yaml`
- Create: `.agents/skills/ideation/references/idea-format.md`
- Create: `.agents/spec/skill_contracts/ideation_spec.rb`

**Interfaces:**
- Consumes: product docs, backlog, prior IDEA manifests, and research verified within 30 days
- Produces: `product/ideas/IDEA-NNN-short-slug/idea/vNNN.md`, its manifest, changelog entry, research versions, and factory run entry

- [ ] **Step 1: Write a failing skill-contract spec**

Assert the skill requires the named Ideator with isolated context, checks research freshness, excludes technical source files, prevents duplicate ideas through semantic comparison, scores the four approved dimensions, validates before manifest update, and logs `success`, `no-op`, or `escalated`.

- [ ] **Step 2: Run the spec and confirm it fails**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/skill_contracts/ideation_spec.rb`

Expected: FAIL because `.agents/skills/ideation/SKILL.md` does not exist.

- [ ] **Step 3: Initialize and write the skill**

Use the project-local skill directory. Keep `SKILL.md` short and route the agent to `idea-format.md`. Require internet research when cached research is older than 30 days or a cited assumption changed. Require direct source links and verification dates. Never auto-approve an idea.

Set UI metadata:

```yaml
interface:
  display_name: "Ideation"
  short_description: "Research and rank product ideas"
  default_prompt: "Use $ideation to research Bootcamper and create versioned product ideas."
```

- [ ] **Step 4: Validate and run the contract spec**

Run:

```bash
python3 /Users/Denys_Zemlianoi/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/ideation
mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/skill_contracts/ideation_spec.rb
git diff --check
```

Expected: validator and spec pass.

- [ ] **Step 5: Commit through the lead workflow**

```bash
git add .agents/skills/ideation .agents/spec/skill_contracts/ideation_spec.rb
bin/lead_bootcamper commit -m "feat: add ideation skill"
```

### Task 4: Add the `idea-analyze` skill

**Files:**
- Create: `.agents/skills/idea-analyze/SKILL.md`
- Create: `.agents/skills/idea-analyze/agents/openai.yaml`
- Create: `.agents/skills/idea-analyze/references/epic-and-gherkin-format.md`
- Create: `.agents/spec/skill_contracts/idea_analyze_spec.rb`

**Interfaces:**
- Consumes: an explicit `IDEA-ID` in `proposed` state and the clarification protocol
- Produces: approved IDEA manifest, stable EPIC directories, versioned `.feature` files, `coverage.yml`, changelog entry, and run log

- [ ] **Step 1: Write the failing contract spec**

Assert the invocation itself records `human-approved`, BA and Ideator use at most three clarification rounds, BA owns every edit, each EPIC has its own Gherkin file, and coverage maps every requirement to happy-path plus relevant edge/error scenario IDs.

- [ ] **Step 2: Confirm failure**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/skill_contracts/idea_analyze_spec.rb`

Expected: FAIL because the skill is absent.

- [ ] **Step 3: Write the skill and format reference**

Require explicit IDEA ID and reject any ID not in `proposed`. Run `bin/product_factory start-run`, spawn BA and Ideator with isolated context, preserve the transcript in `analysis/`, validate outputs, then move the IDEA to `analyzed`. On material product/security/cost/external ambiguity or third unresolved round, write an escalation and retain the last valid state.

- [ ] **Step 4: Add UI metadata**

```yaml
interface:
  display_name: "Analyze Product Idea"
  short_description: "Turn one approved idea into Gherkin epics"
  default_prompt: "Use $idea-analyze with an IDEA ID to approve and analyze that product idea."
```

- [ ] **Step 5: Validate and verify**

Run quick validation for `.agents/skills/idea-analyze`, its focused RSpec file, and `git diff --check`. Expected: all pass.

- [ ] **Step 6: Commit through the lead workflow**

```bash
git add .agents/skills/idea-analyze .agents/spec/skill_contracts/idea_analyze_spec.rb
bin/lead_bootcamper commit -m "feat: add idea analysis skill"
```

### Task 5: Add the `documentation-analyze` skill

**Files:**
- Create: `.agents/skills/documentation-analyze/SKILL.md`
- Create: `.agents/skills/documentation-analyze/agents/openai.yaml`
- Create: `.agents/skills/documentation-analyze/references/ticket-format.md`
- Create: `.agents/spec/skill_contracts/documentation_analyze_spec.rb`

**Interfaces:**
- Consumes: every new or changed `BA-ready` EPIC version and the clarification protocol
- Produces: `TL-approved` EPICs, versioned ticket files, scenario coverage, risk/external-action lists, acyclic dependency matrix, and delivery waves

- [ ] **Step 1: Write the failing contract spec**

Assert full-repository incremental scanning, optional IDEA filter, TL-to-BA three-round protocol, BA-only Gherkin edits, exact scenario references, difficulty 1-5, estimate at most 2 days, no dependency cycles, and no-op behavior.

- [ ] **Step 2: Confirm failure**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/skill_contracts/documentation_analyze_spec.rb`

Expected: FAIL because the skill is absent.

- [ ] **Step 3: Write the skill and ticket format**

Specify a ticket body with observable goal, source IDEA/EPIC/version/scenario IDs, acceptance evidence, dependencies, estimate, difficulty, risks, external actions, and allowed scope. Require TL to process independent EPICs after another EPIC escalates.

- [ ] **Step 4: Add UI metadata**

```yaml
interface:
  display_name: "Analyze Product Documentation"
  short_description: "Turn changed Gherkin epics into atomic tickets"
  default_prompt: "Use $documentation-analyze to incrementally review ready epics and create technical tickets."
```

- [ ] **Step 5: Validate and verify**

Run quick validation, focused RSpec, `bin/product_factory validate --root product`, and `git diff --check`. Expected: all pass.

- [ ] **Step 6: Commit through the lead workflow**

```bash
git add .agents/skills/documentation-analyze .agents/spec/skill_contracts/documentation_analyze_spec.rb
bin/lead_bootcamper commit -m "feat: add documentation analysis skill"
```

### Task 6: Add incremental GitHub backlog reconciliation

**Files:**
- Create: `.agents/skills/backlog-idea/SKILL.md`
- Create: `.agents/skills/backlog-idea/agents/openai.yaml`
- Create: `.agents/skills/backlog-idea/references/github-reconciliation.md`
- Create: `lib/product_factory/github_plan.rb`
- Create: `.agents/spec/lib/product_factory/github_plan_spec.rb`
- Create: `.agents/spec/skill_contracts/backlog_idea_spec.rb`

**Interfaces:**
- Consumes: current ticket manifests, last successful backlog run, `gh issue list --json ...`, and `gh project item-list ... --format json`
- Produces: a deterministic preview of create/update/close/reopen/project-field operations and, after application, stable GitHub mappings in ticket manifests

- [ ] **Step 1: Write failing planner specs**

Cover create, update, close-as-superseded, reopen, unchanged no-op, manual-field drift, ambiguous stable ID, active branch/PR deletion, and merged-PR completion. Represent operations with:

```ruby
ProductFactory::GitHubOperation = Data.define(:action, :ticket_id, :issue_number, :attributes)
```

The planner must be pure: it accepts local and remote hashes and returns operations without executing `gh`.

- [ ] **Step 2: Confirm failure**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/lib/product_factory/github_plan_spec.rb`

Expected: FAIL because `ProductFactory::GitHubPlan` is absent.

- [ ] **Step 3: Implement the pure reconciliation planner**

Use stable Ticket ID markers in issue bodies. Sort operations by Ticket ID and action. Return an escalation operation rather than closing when a branch or PR exists. Treat Git as authoritative for ordinary fields; treat a duplicate or missing mapping with conflicting candidates as ambiguous.

- [ ] **Step 4: Write the skill contract and GitHub procedure**

Use `gh issue create/edit/close/reopen`, `gh project item-add`, and `gh project item-edit`. Verify `gh auth status` includes the `project` scope before mutation. Configure these Project fields: `Idea`, `Epic`, `Ticket ID`, `Priority`, `Status`, `Estimate`, `Dependencies`, `Source Version`, and `Factory Run`.

The official CLI edits one project field per invocation, so apply and log each field operation separately. See [GitHub CLI project commands](https://cli.github.com/manual/gh_project) and [item editing](https://cli.github.com/manual/gh_project_item-edit).

- [ ] **Step 5: Add UI metadata**

```yaml
interface:
  display_name: "Reconcile Product Backlog"
  short_description: "Sync changed factory tickets to GitHub"
  default_prompt: "Use $backlog-idea to incrementally reconcile product tickets with the Bootcamper GitHub Project."
```

- [ ] **Step 6: Validate without external mutation**

Run:

```bash
mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/lib/product_factory/github_plan_spec.rb .agents/spec/skill_contracts/backlog_idea_spec.rb
python3 /Users/Denys_Zemlianoi/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/backlog-idea
git diff --check
```

Expected: all pass. Do not run a live reconciliation during this task.

- [ ] **Step 7: Commit through the lead workflow**

```bash
git add .agents/skills/backlog-idea lib/product_factory/github_plan.rb .agents/spec/lib/product_factory/github_plan_spec.rb .agents/spec/skill_contracts/backlog_idea_spec.rb
bin/lead_bootcamper commit -m "feat: add backlog reconciliation"
```

### Task 7: Add factory mode to the existing Rails delivery workflow

**Files:**
- Modify: `.agents/skills/implement-rails-ticket/SKILL.md`
- Modify: `.agents/skills/implement-rails-ticket/references/preflight-and-approval.md`
- Modify: `.agents/skills/deliver-rails-ticket/SKILL.md`
- Modify: `.agents/skills/deliver-rails-ticket/references/review-and-close.md`
- Create: `.agents/spec/skill_contracts/factory_delivery_mode_spec.rb`

**Interfaces:**
- Consumes: an explicitly user-selected ticket in ordinary mode, or a claimed factory ticket whose IDEA lineage records human approval
- Produces: the unchanged ordinary workflow plus a factory workflow that skips per-ticket selection and plan approval while preserving scope, dependency, security, review, and release gates

- [ ] **Step 1: Write a failing compatibility spec**

Assert ordinary mode still requires explicit ticket selection and exact-plan approval. Assert factory mode requires all of:

```yaml
factory_mode: true
ticket_state: in-progress
claim_run_id: RUN-...
idea_state: analyzed
epic_state: TL-approved
dependencies_satisfied: true
```

Assert factory mode may not merge, expand ticket scope, waive consequential ambiguity, skip dual review, or bypass lead-only release commands.

- [ ] **Step 2: Confirm failure**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/skill_contracts/factory_delivery_mode_spec.rb`

Expected: FAIL because current skills reject backlog selection and lack factory mode.

- [ ] **Step 3: Add the narrow mode switch**

Keep ordinary behavior word-for-word where possible. Add one `Factory Mode` section: verify approved lineage and active claim, treat the immutable ticket version as the approved plan boundary, and pause only for material evidence changes. Reuse the same engineer thread, task record, immutable snapshot, two isolated reviews, remediation, and lead handoff.

- [ ] **Step 4: Make the delivery terminal state explicit**

Lead may commit, push, and open the PR. It must stop with the ticket at `ready-for-human-merge`. Remove or qualify any wording that permits an agent to merge after a generic `skip review`; the product-factory path always requires human merge.

- [ ] **Step 5: Run compatibility verification**

Run:

```bash
mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/skill_contracts/factory_delivery_mode_spec.rb
git diff --check
```

Expected: factory and ordinary contracts both pass.

- [ ] **Step 6: Commit through the lead workflow**

```bash
git add .agents/skills/implement-rails-ticket .agents/skills/deliver-rails-ticket .agents/spec/skill_contracts/factory_delivery_mode_spec.rb
bin/lead_bootcamper commit -m "feat: support factory ticket delivery"
```

### Task 8: Add the `implement` orchestration skill

**Files:**
- Create: `.agents/skills/implement/SKILL.md`
- Create: `.agents/skills/implement/agents/openai.yaml`
- Create: `.agents/skills/implement/references/ticket-selection.md`
- Create: `.agents/spec/skill_contracts/implement_spec.rb`

**Interfaces:**
- Consumes: `bin/product_factory next-ticket`, claim registry, ticket version, and factory mode from Task 7
- Produces: one claimed ticket delivered through `deliver-rails-ticket` to `ready-for-human-merge`, or `no-op`/`escalated`

- [ ] **Step 1: Write the failing skill-contract spec**

Assert priority/dependency-safe selection, one ticket per invocation, shared claim lock, separate branch/worktree, existing named engineer and reviewers, three remediation rounds, release on failure, human-only merge, and no-op when no ticket is available.

- [ ] **Step 2: Confirm failure**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/skill_contracts/implement_spec.rb`

Expected: FAIL because `.agents/skills/implement/SKILL.md` does not exist.

- [ ] **Step 3: Write the selection and cleanup contract**

The skill must:

1. validate product artifacts;
2. allocate a run ID;
3. ask `bin/product_factory next-ticket` for one ticket;
4. claim it before creating a worktree;
5. set its manifest to `in-progress` in a new version;
6. invoke `deliver-rails-ticket` in factory mode;
7. update it to `ready-for-human-merge` after PR creation;
8. release the transient claim on success or failure;
9. record exact recovery instructions when cleanup cannot finish.

Do not use destructive cleanup. Preserve a failed worktree for diagnosis and log its path.

- [ ] **Step 4: Add UI metadata**

```yaml
interface:
  display_name: "Implement Next Product Ticket"
  short_description: "Deliver the next ready ticket to a reviewed PR"
  default_prompt: "Use $implement to claim and deliver the highest-priority available product ticket."
```

- [ ] **Step 5: Validate and verify**

Run quick validation, focused RSpec, and `git diff --check`. Expected: all pass.

- [ ] **Step 6: Commit through the lead workflow**

```bash
git add .agents/skills/implement .agents/spec/skill_contracts/implement_spec.rb
bin/lead_bootcamper commit -m "feat: add factory implementation skill"
```

### Task 9: Run end-to-end fixture validation and document invocation

**Files:**
- Create: `.agents/spec/fixtures/product_factory/approved_idea/**`
- Create: `.agents/spec/system/product_factory_pipeline_spec.rb`
- Modify: `README.md`

**Interfaces:**
- Consumes: every artifact, agent, CLI, and skill contract from Tasks 1-8
- Produces: one offline fixture proving cumulative transitions and a short command reference for the five phases

- [ ] **Step 1: Add the fixture**

Create one IDEA with two EPICs and three tickets. Include one dependency, one changed BA version with a reason, one superseded ticket, one merged ticket, and one newly unblocked ticket. Keep all timestamps fixed.

- [ ] **Step 2: Write the failing end-to-end spec**

The spec copies the fixture to a temporary directory and proves:

```ruby
expect(first_scan.map(&:status)).to contain_exactly("new", "new", "new")
expect(second_scan).to be_empty
expect(changed_scan.map { [_1.id, _1.status] }).to include(["EPIC-001", "changed"])
expect(repository.next_ticket.fetch("id")).to eq("TICKET-002")
expect { validator.validate! }.not_to raise_error
```

Feed recorded GitHub JSON to `GitHubPlan`; do not contact GitHub.

- [ ] **Step 3: Run the spec and fix only integration defects**

Run: `mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/system/product_factory_pipeline_spec.rb`

Expected before fixes: FAIL on the first mismatched shared contract. Apply the minimum fix to the owning Task 1-8 file, then rerun until PASS.

- [ ] **Step 4: Add the operator commands to README**

Document only:

```text
$ideation
$idea-analyze IDEA-001
$documentation-analyze
$backlog-idea
$implement
```

Explain in one sentence that Git artifacts are canonical, each phase is incremental, and a human must merge every PR. Link the design spec and artifact contract.

- [ ] **Step 5: Run the complete gate**

Run:

```bash
mise exec ruby@4.0.6 -- bundle exec rspec .agents/spec/lib/product_factory_spec.rb .agents/spec/lib/product_factory/github_plan_spec.rb .agents/spec/agent_contracts .agents/spec/skill_contracts .agents/spec/system/product_factory_pipeline_spec.rb
for skill in ideation idea-analyze documentation-analyze backlog-idea implement; do python3 /Users/Denys_Zemlianoi/.codex/skills/.system/skill-creator/scripts/quick_validate.py ".agents/skills/$skill"; done
git diff --check
```

Expected: all specs and skill validators pass; `git diff --check` prints nothing.

- [ ] **Step 6: Perform isolated forward tests**

In a temporary copy of the fixture, invoke each skill with its realistic command. Permit no live GitHub mutation. Verify each agent writes only its owned artifacts, each rerun returns no-op, and the third unresolved clarification produces an escalation packet.

- [ ] **Step 7: Commit through the lead workflow**

```bash
git add .agents/spec/fixtures/product_factory .agents/spec/system/product_factory_pipeline_spec.rb README.md
bin/lead_bootcamper commit -m "test: verify product factory pipeline"
```

## Final Verification

- [ ] Run `mise exec ruby@4.0.6 -- bundle exec rspec` and confirm zero failures.
- [ ] Run `mise exec ruby@4.0.6 -- bundle exec rubocop --cache false` and confirm zero offenses.
- [ ] Run `git diff --check` and confirm no output.
- [ ] Run `git status --short` and confirm only pre-existing unrelated user changes remain.
- [ ] Inspect the commit list and confirm each task produced one scoped lead-authorized commit.
- [ ] Do not push, create a live GitHub Project, mutate live Issues, or merge without the separate authorization required at execution time.
