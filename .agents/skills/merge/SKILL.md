---
name: merge
description: Manually authorize and merge one reviewed Product Factory pull request, then reconcile its ticket to done.
---

# Merge Reviewed Ticket

This skill is explicit-only: never merge as part of implementation, review, CI,
or backlog automation. Run it only when a human invokes `$merge PR-NUMBER`.

Before mutation, verify the pull request targets the configured base branch,
belongs to a ticket in `ready-for-human-merge`, has passing required checks,
has no unresolved review threads, and passes the review gate. Normally this
requires at least one GitHub approval. When repository variable
`SOLO_MAINTAINER=true`, GitHub approval is waived, but the task artifact must
contain a documented `APPROVED` verdict from one independent reviewer agent
(fresh-eye or project-context) for that exact commit. The human-invoked
`$merge` command must verify this evidence before mutation. If any gate fails,
leave the PR and ticket unchanged and report the exact blocker.

Only the project-scoped `lead_bootcamper` agent may execute
`bin/lead_bootcamper merge`. Do not use `gh pr merge` directly and do not merge
through implementation or reviewer agents.

After a successful merge, invoke the project-scoped `bootcamper_backlogger` in
a fresh context with the merged PR number, ticket ID, merge commit, and the
existing factory run/snapshot. The backlogger must idempotently publish the
next immutable ticket version as `done`, update the GitHub Project Status to
`Done`, and recalculate dependency-safe tickets. A failed post-merge sync does
not undo the merge or mark the ticket done; preserve the reconciliation run and
resume it automatically from its snapshot.

Record the merge and reconciliation evidence in the human-readable factory
journal. Never close the ticket before the merged commit is confirmed.
