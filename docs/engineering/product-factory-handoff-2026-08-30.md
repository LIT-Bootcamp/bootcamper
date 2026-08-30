# Product Factory Handoff

Date: 2026-08-30  
Repository: `LIT-Bootcamp/bootcamper`  
Factory branch: `feat/product-factory`  
Factory worktree: `/private/tmp/bootcamper-product-factory`

## Objective

Finish a cumulative, versioned product factory that converts researched product ideas into human-approved, reviewed pull requests:

```text
Ideator -> IDEA
IDEA has many EPICs managed by BA
EPIC has many TICKETs managed by TL and Backlogger
TICKET -> implementation -> two independent reviews -> PR -> human merge
```

Git files are canonical. One GitHub Project presents the approved engineering backlog. Every artifact change creates a new immutable version and records a reason.

## User decisions

- Keep all factory artifacts and configuration in the project repository.
- Write factory artifacts and skill documentation in English.
- Keep each phase as a separate skill: `ideation`, `idea-analyze`, `documentation-analyze`, `backlog-idea`, and `implement`.
- Make every phase cumulative and incremental. Agents must read prior versions and successful run checkpoints before creating or changing artifacts.
- Record a human-readable append-only journal plus small machine-readable YAML manifests.
- Store a reason for every artifact version change.
- Use one GitHub Project for Bootcamper.
- Ideator works as a product owner, researches users and competitors, ranks ideas, and does not inspect technical implementation.
- A human decides whether an IDEA deserves further work.
- BA owns business flows and complete Gherkin scenarios. BA avoids technical design.
- TL owns technical analysis, atomic tickets, dependency DAGs, delivery waves, risks, estimates, external actions, and scenario-to-ticket coverage.
- TL asks BA questions through a bounded clarification loop. BA edits BA-owned artifacts. TL does not block independent work because another question remains open.
- Backlogger creates and updates GitHub issues and Project fields incrementally. It computes semantic differences from the last successful run.
- Backlogger closes superseded tickets, except when an active branch or PR makes closure unsafe. That case requires escalation.
- `implement` claims one highest-priority dependency-safe ticket per invocation.
- Existing developer and dual-review workflows remain the delivery mechanism. Every product-factory PR requires human merge.
- Agents ask the human when an action violates a rule, creates an ambiguous mapping, changes product/security/cost commitments, or fails to converge after three clarification/review rounds.
- Before every push, run database preparation, the complete quality gate, and the full RSpec suite. Fix failures before pushing.
- Do not create a new live backlog until the factory passes its offline end-to-end gate.

## Legacy GitHub backlog retirement

The previous flat import did not use the factory model. It contained 122 MVP tickets and 12 post-MVP capabilities. All 134 issues lacked labels, all Project items had `Todo`, and the Project lacked the required factory fields.

The user authorized closing the import and restarting through the factory.

Completed external changes:

- Verified the exact legacy issue range: `#2` through `#135`.
- Saved pre-change snapshots:
  - `/tmp/bootcamper-project-legacy-snapshot.json`
  - `/tmp/bootcamper-legacy-issues-snapshot.json`
- Closed issues `#2` through `#135` with reason `not planned` and this comment:

  > Legacy flat backlog import retired. The backlog will be regenerated from versioned product-factory artifacts after the factory passes its end-to-end gate.

- Removed all 134 legacy items from GitHub Project `LIT-Bootcamp/1`.
- Verified the final external state:
  - Project items: `0`
  - Open repository issues: `0`
  - Closed legacy issues with `NOT_PLANNED`: `134`

Do not reopen or re-import these records. The new `backlog-idea` reconciliation must create new issues from approved versioned TICKET artifacts.

## Current audited status

Tasks 1–9 from `docs/superpowers/plans/2026-08-27-product-factory.md` are implemented on `feat/product-factory`. The branch includes the three analysis skills, `backlog-idea`, factory delivery mode, `implement`, and the offline end-to-end fixture. The legacy text below records the state at the original session boundary; its “remaining” tasks are no longer outstanding.

The continuation audit found and fixed two first-run reconciliation hazards:

- the built-in GitHub Project `Status` field now produces a `project_field_update` preview when its options differ from the factory lifecycle;
- duplicate managed Project field names now escalate instead of being silently collapsed.

No live factory backlog has been created. The GitHub Project remains empty until a human authorizes the exact `$backlog-idea` preview.

## Implemented factory components at the original handoff

Before this handoff file was added, the isolated factory worktree was clean at commit `de42055`. The handoff file itself is currently untracked and intentionally uncommitted for the next session to review.

Implemented commits:

```text
be0bcdc docs: define product factory
3fd61f6 docs: plan product factory
8dcfba5 feat: add product factory contracts
c1b97f3 fix: preserve product factory run records
ce0a116 feat: add product factory agents
9a40b7e fix: tighten product factory contracts
ee2c7d8 feat: add ideation skill
1d43d3d feat: add idea analysis skill
208f6a9 fix: validate idea analysis artifacts
39d548f refactor: isolate product factory tests
de42055 feat: add documentation analysis skill
```

Implemented skills:

- `.agents/skills/ideation/`
- `.agents/skills/idea-analyze/`
- `.agents/skills/documentation-analyze/`

Implemented named agents:

- `.codex/agents/bootcamper-ideator.toml`
- `.codex/agents/bootcamper-business-analyst.toml`
- `.codex/agents/bootcamper-technical-lead.toml`
- `.codex/agents/bootcamper-backlogger.toml`
- existing engineer, lead, and two reviewer agents

Implemented core:

- `lib/product_factory.rb`
  - artifact validation
  - immutable version ancestry and change reasons
  - lifecycle validation
  - requirement and scenario coverage
  - dependency-cycle checks
  - incremental snapshots and change classification
  - dependency-safe ticket selection
  - append-only run records
  - cross-worktree ticket claims
- `bin/product_factory`
  - `validate`
  - `changes`
  - `start-run`
  - `finish-run`
  - `next-ticket`
  - `release-ticket`
- `docs/product-factory/artifact-contract.md`
- `docs/product-factory/clarification-protocol.md`
- empty canonical roots under `product/`

The current implementation supports the pipeline through TL ticket creation:

```text
ideation -> idea-analyze -> documentation-analyze
```

## Historical approved plan (now implemented)

The source plan is `docs/superpowers/plans/2026-08-27-product-factory.md`. The following was the original remaining scope and is retained as implementation context.

### Task 6: `backlog-idea`

Create:

- `.agents/skills/backlog-idea/SKILL.md`
- `.agents/skills/backlog-idea/agents/openai.yaml`
- `.agents/skills/backlog-idea/references/github-reconciliation.md`
- `lib/product_factory/github_plan.rb`
- `.agents/spec/lib/product_factory/github_plan_spec.rb`
- `.agents/spec/skill_contracts/backlog_idea_spec.rb`

The planner must remain pure. It accepts local and recorded remote hashes and returns deterministic `ProductFactory::GitHubOperation` values. Cover:

- create
- update
- close superseded
- reopen
- unchanged no-op
- unmanaged manual-field drift
- duplicate or ambiguous stable ID
- active branch or PR protection
- merged-PR completion
- stable sorting by Ticket ID and action

Use stable TICKET-ID markers in issue bodies. Configure these Project fields during authorized apply:

- Idea
- Epic
- Ticket ID
- Priority
- Status
- Estimate
- Dependencies
- Source Version
- Factory Run

Each `gh project item-edit` updates one field and must produce a journal entry. Require `gh auth status` with project scope. Keep preview separate from apply. Do not perform live reconciliation while implementing this task.

At the original handoff no Task 6 files existed; they are now committed.

### Task 7: factory delivery mode

Extend the existing `implement-rails-ticket` and `deliver-rails-ticket` skills. Preserve ordinary mode. Factory mode requires:

```yaml
factory_mode: true
ticket_state: in-progress
claim_run_id: RUN-...
idea_state: analyzed
epic_state: TL-approved
dependencies_satisfied: true
```

Factory mode uses the immutable ticket version as the approved scope boundary. It keeps dependency, security, test, dual-review, remediation, and lead-release gates. It stops at `ready-for-human-merge`.

### Task 8: `implement`

Create the orchestration skill that:

1. validates artifacts;
2. creates a run;
3. selects one ticket through `bin/product_factory next-ticket`;
4. claims it before creating a worktree;
5. publishes an `in-progress` version;
6. invokes `deliver-rails-ticket` in factory mode;
7. advances to `ready-for-human-merge` after PR creation;
8. releases the transient claim;
9. preserves failed worktrees and records recovery instructions.

No automatic merge is allowed.

### Task 9: offline end-to-end gate

Add one fixed fixture with:

- one IDEA
- two EPICs
- three TICKETs
- one dependency
- one changed BA version with a reason
- one superseded ticket
- one merged ticket
- one newly unblocked ticket

Prove incremental first-run, no-op rerun, changed artifact detection, next-ticket selection, validation, and GitHub planning with recorded JSON. Do not contact GitHub from the system spec.

Document only these operator commands in README:

```text
$ideation
$idea-analyze IDEA-001
$documentation-analyze
$backlog-idea
$implement
```

## Required verification

Run the task-specific RED/GREEN specs from the plan. Before integration, run:

```bash
mise exec ruby@4.0.6 -- bundle exec rspec \
  .agents/spec/lib/product_factory_spec.rb \
  .agents/spec/lib/product_factory/github_plan_spec.rb \
  .agents/spec/agent_contracts \
  .agents/spec/skill_contracts \
  .agents/spec/system/product_factory_pipeline_spec.rb

for skill in ideation idea-analyze documentation-analyze backlog-idea implement; do
  python3 /Users/Denys_Zemlianoi/.codex/skills/.system/skill-creator/scripts/quick_validate.py ".agents/skills/$skill"
done

git diff --check
```

Then run the repository-wide RSpec and RuboCop gates. Perform realistic forward tests in temporary fixture copies with no live GitHub mutation. A second unchanged run must return `no-op`.

## Branch and integration state

- `feat/product-factory` has no pull request yet and is ahead of its remote tracking branch.
- PR `#136` (`ci/optimized-pipeline`) was green and mergeable when checked.
- Branch `ops/OPS-001-lead-release-workflow` contains the new local pre-push quality gate and RSpec improvements. Commits:
  - `f4262a1 Improve local test and quality gates`
  - `e43e56b Document upcoming engineering tasks`
- The product-factory branch must synchronize with current repository changes before its final gate and PR.
- Do not merge automatically. The user performs or explicitly authorizes human merge.

## Immediate next action

Choose how to integrate `feat/product-factory`. After integration, run the first blank-slate ideation cycle; do not mutate GitHub until the resulting backlog preview is explicitly approved.
