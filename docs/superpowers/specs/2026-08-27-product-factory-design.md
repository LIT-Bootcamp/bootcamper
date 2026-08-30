# Product Factory Design

## Purpose

Bootcamper needs a traceable pipeline that turns product research into reviewed pull requests. Git stores the canonical artifacts and their history. One GitHub Project presents the approved engineering backlog.

The factory runs in five separate, manually invoked phases. Each phase processes new or changed input and produces versioned output. A rerun with unchanged input records a no-op.

## Decisions

- A human approves each idea by invoking `idea-analyze IDEA-ID`.
- BA and TL resolve requirements without a human approval gate.
- Backlogger may create, update, and close GitHub Issues.
- Developer may select the highest-priority unblocked ticket.
- A human alone may merge a pull request.
- Agents may make explicit assumptions and continue. They escalate choices that materially change product behavior, security, cost, or an external commitment.
- All factory artifacts use English.
- Estimates use ideal engineering days. A ticket may not exceed two ideal days.

## Domain Model

```text
IDEA has many EPICs
EPIC has many TICKETs
TICKET maps to one GitHub Issue and, during delivery, one pull request
```

The agent ownership model is:

| Artifact | Owner | Responsibility |
| --- | --- | --- |
| IDEA | Ideator | Product problem, evidence, priority, and business rationale |
| EPIC and Gherkin | BA | Business flows, scenarios, and requirement coverage |
| TICKET and dependency graph | TL | Technical decomposition, risk, estimates, and delivery waves |
| GitHub Issue projection | Backlogger | Incremental reconciliation with Git artifacts |
| Commit and pull request | Developer and delivery agents | Implementation, verification, review, and delivery preparation |

## Repository Layout

```text
product/
├── factory-log/
├── research/
└── ideas/
    └── IDEA-001-short-slug/
        ├── idea/
        │   ├── v001.md
        │   └── manifest.yml
        ├── epics/
        │   └── EPIC-001-short-slug/
        │       ├── requirements/
        │       │   ├── v001.feature
        │       │   └── coverage.yml
        │       ├── analysis/
        │       └── tickets/
        │           └── TICKET-001-short-slug/
        │               ├── v001.md
        │               └── manifest.yml
        └── changelog.md
```

Each version file is immutable. Its metadata records the stable ID, version, author agent, run ID, creation time, previous version, reason for change, source artifact versions, content hash, assumptions, and unresolved questions. A manifest points to the current version and lifecycle state.

Git retains every committed version. The factory also keeps each artifact version as a physical file so an agent can compare runs without reconstructing old files from Git history.

## Lifecycle

```text
IDEA:
proposed -> human-approved -> analyzed

EPIC:
draft -> BA-ready -> TL-review -> TL-approved

TICKET:
draft -> backlog-ready -> available -> in-progress
-> in-review -> ready-for-human-merge -> done

Exceptional:
blocked | superseded | escalated
```

Only the owning agent writes a new artifact version. Reviewers submit questions or findings. The owner answers by writing a new version with a change reason.

## Skills

### `ideation`

The skill spawns Ideator. Ideator reads the current product, backlog, previous ideas, and research. It does not inspect technical implementation. It generates a ranked set of product ideas and saves each idea separately.

Ideator scores user benefit, progressiveness, business value, and confidence from 1 to 5. It uses those scores as evidence for an argued priority rather than calculating priority from a fixed formula.

Competitor and market research stays reusable for 30 days. Ideator refreshes expired sources and any assumption affected by newer evidence. Each idea cites its sources and their verification dates.

### `idea-analyze`

Invoking `idea-analyze IDEA-ID` records human approval of that idea. The skill spawns BA and runs the BA-to-Ideator clarification protocol. BA decides when it has enough information.

BA splits the idea into stable EPICs and writes one Gherkin document per EPIC. BA also writes a coverage matrix from every requirement to its happy-path and relevant edge or error scenarios.

### `documentation-analyze`

The skill scans all EPICs and processes only new or changed BA versions. It spawns TL, which reviews the Gherkin and sends questions to BA. BA alone revises BA artifacts.

After TL accepts the scenarios, it creates versioned tickets, a dependency matrix, and delivery waves. Each ticket references exact scenario IDs or lines. TL records difficulty on a five-point scale, ideal-day estimate, risks, assumptions, external actions, and dependencies.

TL must produce an acyclic dependency graph. Every Gherkin scenario must map to at least one ticket, each ticket must map to a scenario, and no ticket may exceed two ideal days.

### `backlog-idea`

The skill scans all TL output and compares current source versions and content hashes with its last successful run. An optional IDEA ID limits the scan but does not change its incremental behavior.

Backlogger maintains a stable `TICKET-ID <-> GitHub Issue ID` mapping. It creates, updates, closes, and reopens issues to match Git. A deleted ticket closes as `superseded`. If implementation or a pull request already exists, Backlogger escalates instead of closing it.

Backlogger also reconciles merged pull requests, marks their tickets done, and makes newly unblocked tickets available. It writes a preview to the factory log before applying changes. Ambiguous mappings and conflicting manual GitHub edits cause escalation.

### `implement`

Each invocation atomically claims one highest-priority available ticket. Parallel invocations use separate branches and worktrees, so two developers cannot claim the same ticket.

The skill reuses the existing Rails implementation, review, and delivery skills. It produces a tested commit and pull request, runs project-context and fresh-eye reviewers independently, and drives fixes through repeated review. Three failed fix-and-review cycles cause escalation.

The terminal state is `ready-for-human-merge`. No agent may merge the pull request.

## Agent Contracts

### Ideator

Ideator acts as a product owner. It focuses on user benefit, product progress, evidence, and business priority. It does not propose architecture or inspect application code.

### Business Analyst

BA turns an approved idea into complete observable behavior. It owns EPIC boundaries, Gherkin, coverage, assumptions, and answers to TL. BA avoids implementation detail.

### Technical Lead

TL reads the product artifacts and codebase. It tests scenario completeness, identifies risks and external work, and decomposes accepted EPICs into independent tickets. It does not edit BA-owned files.

### Backlogger

Backlogger projects approved tickets into GitHub. It does not change business requirements or technical scope.

### Delivery Agents

Developer implements one ticket. The GitHub specialist pushes and prepares the pull request. Two independent reviewers assess the immutable change. Existing Rails delivery skills remain the implementation mechanism.

## Clarification Protocol

Both BA-to-Ideator and TL-to-BA conversations use one shared reference rather than a separate skill.

Each round contains numbered questions, direct answers, resolved items, open items, and assumptions. The artifact owner publishes a new version when answers change its artifact. After three unresolved rounds, the phase records an escalation with the transcript and preserves all independent progress.

## Incremental Run Protocol

Every skill run follows the same protocol:

1. Allocate a run ID and append a `started` log entry.
2. Compare artifact versions and content hashes with the last successful run.
3. Classify inputs as new, changed, deleted, newly unblocked, or unchanged.
4. Process only actionable inputs.
5. Validate new artifacts before changing manifests.
6. Append `success`, `no-op`, or `escalated` with affected IDs and the next action.

A failure for one IDEA or EPIC does not stop independent work. The phase retains its prior successful checkpoint until new output passes validation.

## Logging

The factory keeps two append-only logs:

- A global log records run ID, skill, timestamps, inputs, outputs, status, external changes, errors, and next action.
- Each idea changelog records artifact version changes and their reasons.

The logs favor readable Markdown. Machine state stays in small YAML manifests; the factory does not introduce a database or workflow engine.

## GitHub Project

One GitHub Project covers Bootcamper. The projection includes these fields:

- Idea
- Epic
- Ticket ID
- Priority
- Status
- Estimate
- Dependencies
- Source Version
- Factory Run

Git remains authoritative when GitHub and Git disagree. Backlogger may reconcile ordinary field drift. It escalates manual changes that would discard implementation work or make identity mapping ambiguous.

## Quality Gates

| Phase | Gate |
| --- | --- |
| Ideation | Sources, verification dates, four scores, priority rationale, and no technical solutioning |
| BA | Valid Gherkin, explicit assumptions, and complete requirement coverage matrix |
| TL | Full scenario-to-ticket coverage, no orphan tickets, acyclic DAG, and two-day ticket limit |
| Backlog | Stable ID mapping, exact semantic diff, and idempotent rerun |
| Implementation | Ticket-scoped tests, repository quality gates, two independent reviews, green CI, and no unresolved findings |

One shared artifact validator checks manifests, references, state transitions, hashes, version ancestry, coverage, and dependency cycles. Backlog fixtures verify create, update, delete, no-op, and conflict reconciliation without mutating GitHub.

## Escalation Rules

Agents record an assumption and continue when the remaining uncertainty does not change product behavior, security, cost, or an external commitment. They escalate when:

- an ambiguity materially changes one of those areas;
- an artifact violates ownership or lifecycle rules;
- stable IDs or GitHub mappings conflict;
- a ticket with active implementation would be closed or replaced;
- three clarification or code-review cycles fail to converge;
- required credentials, access, or external action are unavailable.

An escalation identifies the affected artifacts, completed work, failed rule, available choices, and exact action needed from the human.

## Scope Boundaries

The first version does not add a scheduler, daemon, database, web dashboard, or general workflow engine. A human invokes each phase separately. Git, manifests, GitHub, and the existing agent framework cover the required coordination.

The factory can add scheduled ideation after real use shows that manual invocation misses valuable product opportunities.
