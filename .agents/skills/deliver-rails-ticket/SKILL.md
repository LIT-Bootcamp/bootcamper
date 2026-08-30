---
name: deliver-rails-ticket
description: Deliver one explicitly identified Ruby on Rails ticket by orchestrating approval-gated implementation with the Senior Ruby/Rails Engineer agent, an immutable product snapshot, two isolated reviewer agents, remediation, and final task logging. Use for end-to-end delivery; do not select backlog work or use for broad product planning.
---

# Deliver Rails Ticket

Orchestrate one ticket without implementing or reviewing product code in the coordinator thread. This workflow composes the project-local skills at `.agents/skills/implement-rails-ticket/` and `.agents/skills/review-rails-change/`, plus their named custom agents in `.codex/agents/`. Skills own lifecycle and evidence contracts; agents own technical judgment and reviewer perspective. Do not substitute global copies when the project-local files are available.

## Prerequisites

Require a user-selected stable ticket ID; the `implement-rails-ticket` and `review-rails-change` skills; project-scoped agents in `.codex/agents/` named `senior_ruby_rails_engineer`, `fresh_eye_rails_reviewer`, and `project_context_rails_reviewer` (or each skill's faithful isolated fallback); and capacity to preserve implementer continuity and isolate reviewer contexts. If any prerequisite is unavailable, disclose it and stop before product mutation. Never choose the next backlog ticket.

In Factory Mode, replace only the user-selection prerequisite with a canonical immutable ticket version and the verified factory envelope required by `implement-rails-ticket`. The ticket was selected and claimed upstream; this skill must not choose another one.

## Implement

Read and follow `implement-rails-ticket` through its approval gate, execution, task record, self-review, and immutable `ready_for_review` handoff. Do not duplicate or bypass its preflight. The exact approved plan remains the scope boundary for later remediation.

In Factory Mode, follow the `Factory Mode` section instead: the immutable ticket version is the approved scope boundary, and per-ticket selection and exact-plan approval are skipped. Reuse the same engineer thread and all ordinary implementation, dependency, security, test, task-record, self-review, and immutable-handoff gates.

## Review and Close

After implementation, read [review-and-close.md](references/review-and-close.md). Use `review-rails-change` twice against the identical sanitized snapshot: `fresh-eye` mode with `fresh_eye_rails_reviewer`, and `project-context` mode with `project_context_rails_reviewer`. Neither reviewer may receive the task record, implementation discussion, rationale, worklog, challenges, claimed verification results, prior findings, or the other review. Run them concurrently only with isolated worktrees, test databases, and temporary paths; otherwise serialize execution without sharing findings.

The ticket is complete only when acceptance criteria and required checks pass, both final verdicts are `APPROVE`, no Critical or Major finding remains, and the task record is finalized. Hand the finalized ticket to `lead_bootcamper`; only that agent may run lead-only commit, push, pull-request, or separately authorized ordinary-mode release commands. Do not deploy, close an external ticket, or mutate production.

Factory Mode must not skip dual review, bypass remediation, expand the immutable ticket scope, or bypass `lead_bootcamper`. The lead may commit, push, and open the pull request, then the workflow must stop with the ticket at `ready-for-human-merge`. Only a human may merge a Factory Mode pull request; generic review skipping or agent approval is not merge authorization.
