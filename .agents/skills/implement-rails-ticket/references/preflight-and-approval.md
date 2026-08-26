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
