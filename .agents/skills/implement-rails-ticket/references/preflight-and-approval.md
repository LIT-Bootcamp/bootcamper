# Preflight and Approval

## Coordinator Preflight

Use read-only inspection to establish:

1. Exact ticket ID, authoritative wording, acceptance criteria, scope, and explicit non-goals. If an existing authoritative ticket with that ID differs from the supplied contract, stop and ask the user to confirm an explicit amendment or provide a new stable ID; never let a conflicting prompt silently redefine the ticket.
2. Scoped repository instructions and any conflict with the ticket or safe Rails operation.
3. Ticket dependencies and completion evidence.
4. Existing worktree changes that overlap the ticket.
5. Pinned Ruby, Rails, test framework, database, and quality-tool versions. If the Rails application or required toolchain is absent, return `BLOCKED` before task-record creation or mutation unless project initialization is explicitly added to scope and approved as part of the resolved plan.
6. Repository task-record policy; default directory is `docs/engineering/tasks`.
7. Availability of the project-scoped `.codex/agents/senior-ruby-rails-engineer.toml` custom agent or the faithful isolated fallback described by the skill.

If the user supplies work without a stable ID, ask them to assign one; do not invent it. Stop on a record filename collision with a different task. Missing optional architecture, backlog, prior logs, or Git history does not block work. Missing evidence required by an explicit dependency does.

## Planning Packet

Create the engineer with the project path, exact ticket and acceptance criteria, approved product context relevant to the ticket, repository instructions and relevant documents, preflight observations/conflicts, and a strict read-only instruction. Require consequential questions, reversible assumptions, risks, test strategy, dependency concerns, and a provisional plan.

Do not provide a preferred implementation design. Let the engineer trace the repository and propose it.

## Resolved Plan

Consequential questions can affect scope, behavior, architecture, dependencies, security, privacy, data integrity, destructive operations, migrations, external services, or public UX. Present all of them to the user. A blanket approval does not answer unresolved questions.

Forward every answer to the same engineer and request a resolved plan containing bounded steps, explicit non-goals, TDD or alternative verification by change type, expected components and data changes, risks, rollout/rollback considerations, reversible assumptions, and the self-review/immutable-handoff plan.

Ask the user to approve execution of that exact plan. Record approval only after a clear affirmative response. Any material revision requires fresh approval.

## Factory Mode Preflight

Factory Mode may skip per-ticket plan approval only after read-only verification of the complete factory envelope:

```yaml
factory_mode: true
ticket_state: in-progress
claim_run_id: RUN-...
idea_state: analyzed
epic_state: TL-approved
dependencies_satisfied: true
```

Resolve the canonical immutable ticket version and prove that it belongs to a human-approved IDEA lineage, the referenced EPIC is `TL-approved`, the ticket is `in-progress`, every dependency is satisfied, and the claim registry contains an active claim for the same ticket and `claim_run_id`. A stale claim, conflicting version, failed dependency, or incomplete lineage is `BLOCKED`; do not fall back to ordinary mode silently.

Send the immutable ticket version, acceptance criteria, explicit non-goals, allowed scope, lineage evidence, dependency evidence, and claim identity to the same engineer as the approved scope boundary. The engineer still identifies risks, test strategy, reversible assumptions, and consequential ambiguity, but does not ask for approval of a substitute implementation plan. Stop before mutation for any unanswered consequential question. When material evidence changes behavior, architecture, dependencies, public contracts, security/privacy, cost, data integrity, migration strategy, or destructive effects, require a newly approved immutable ticket version; approval of the original lineage does not waive that change.
