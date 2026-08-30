---
name: review-rails-change
description: Run one independent, read-only review of an immutable sanitized Ruby on Rails change using either the fresh-eye or project-context custom reviewer agent and evidence-based severity findings. Do not implement fixes or review mutable/unidentified work.
---

# Review Rails Change

Coordinate one review without reviewing or editing product code in the coordinator thread. This skill owns packet construction, isolation, verification protocol, findings format, and verdict lifecycle. Reviewer agents own only their independent perspective and technical judgment. Require exactly one mode: `fresh-eye` or `project-context`.

## Agent Selection

- `fresh-eye`: spawn the project-scoped custom agent `fresh_eye_rails_reviewer` from `.codex/agents/fresh-eye-rails-reviewer.toml` with no inherited conversation and no project-history context.
- `project-context`: spawn the project-scoped custom agent `project_context_rails_reviewer` from `.codex/agents/project-context-rails-reviewer.toml` with no inherited conversation and only the allowed project context named in the packet.

Do not silently substitute a generic reviewer. If named custom-agent selection is unavailable, load the matching project TOML and supply its `developer_instructions` unchanged to a new isolated subagent. If faithful isolation is unavailable, return `BLOCKED`.

## Required Packet

Read [review-contract.md](references/review-contract.md). The packet must identify the ticket, exact acceptance criteria, approved requirement clarifications, immutable product snapshot and digest, changed-file manifest, excluded operational paths, independent verification commands, isolated environment, and mode-appropriate context paths.

Treat the packet as immutable. Never provide or read the current task record, implementation conversation, rationale, worklog, challenges, claimed verification results, prior findings, or another review. Reject context paths that equal, contain, or resolve through an excluded path. A product snapshot change makes the verdict obsolete.

## Review Method

Verify snapshot identity before inspection and after checks. The reviewer inspects the diff and relevant surrounding code, independently runs supplied commands in the assigned isolated environment, and adds focused checks as needed. Do not trust an implementer's claimed results.

Prioritize correctness, acceptance criteria, authorization/security, privacy, data integrity, migrations, concurrency/idempotency, regressions, Rails/Ruby/test conventions, maintainability, accessibility, and missing tests in proportion to the change.

Report with [findings-format.md](references/findings-format.md). Do not edit tracked files, create commits, push, open pull requests, or communicate with the other reviewer before the initial verdict.

End with exactly one: `APPROVE` (no open Critical or Major findings), `CHANGES REQUIRED` (at least one Critical or Major finding), or `BLOCKED` (the immutable snapshot, isolation, or evidence needed for responsible review is unavailable).
