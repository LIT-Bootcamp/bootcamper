---
name: implement-rails-ticket
description: Plan and implement one explicitly identified Ruby on Rails ticket through an approval gate, a named Senior Ruby/Rails Engineer agent, proportional TDD, durable task logging, self-review, and an immutable review-ready handoff. Use for implementation only; do not select backlog work, perform independent review, or mark a ticket delivered.
---

# Implement Rails Ticket

Coordinate one implementation without writing product code in the coordinator thread. This skill owns lifecycle, approval gates, task records, and handoff. The custom agent `senior_ruby_rails_engineer` owns technical investigation, planning, implementation, tests, self-review, and in-scope remediation. The coordinator owns user communication, authorization state, and context isolation.

## Agent Requirement

Spawn the project-scoped custom agent named `senior_ruby_rails_engineer` from `.codex/agents/senior-ruby-rails-engineer.toml` with no inherited conversation. Do not silently substitute a generic worker. If the runtime cannot select named custom agents but can create an isolated subagent, read that project TOML and supply its `developer_instructions` unchanged as the fallback agent contract. Record that fallback in the task record. If neither named selection nor faithful isolated fallback is possible, stop before implementation.

Reuse the same agent thread for planning, execution, and remediation so discoveries survive without exposing the coordinator's unrelated conversation.

## Preflight and Approval

Before any file mutation, generator, dependency installation, task-record creation, commit, or external change, read [preflight-and-approval.md](references/preflight-and-approval.md) and complete the read-only preflight.

Required invariants:

- The user explicitly selects a stable ticket identifier; never choose backlog work.
- Dependencies are proven satisfied or explicitly waived.
- Every consequential question is explicitly answered.
- The engineer produces the resolved plan after receiving those answers.
- The user approves that exact plan. A material change invalidates approval.

## Implementation

After approval, read [implementation-workflow.md](references/implementation-workflow.md), resume the same engineer, and create exactly one task record from [task-record.md](references/task-record.md). Default to `docs/engineering/tasks` only when the repository defines no location.

Implement only the approved plan. Pause for a revised plan when evidence changes behavior, architecture, dependencies, public contracts, security/privacy, data integrity, migration strategy, or destructive effects. Preserve unrelated work.

## Handoff Boundary

This skill ends at `ready_for_review`, not `completed`. Return the immutable product snapshot identity and changed-file manifest, changed product paths excluding the operational task record, independent verification commands, acceptance-criterion evidence, remaining risks or reversible assumptions, and task-record path.

Do not perform an independent review, issue reviewer verdicts, commit, merge, deploy, close an external ticket, or mark the record completed. Use `deliver-rails-ticket` when dual review and final delivery are required.
