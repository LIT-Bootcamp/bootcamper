---
name: merge
description: Use when a human explicitly requests merging one reviewed Product Factory pull request.
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

After a successful merge, the post-merge CI reconciler owns completion. It must
idempotently publish canonical Git ticket versions (`done` plus newly unblocked
`available` tickets) before GitHub Project `Status` and `Source Version` are
updated. The reconciler must fail visibly when validation, commit, push,
mapping, or Project projection fails; a green no-op with a present ticket
marker is forbidden. Rerunning the same workflow is the recovery path.

`$merge` reports the post-merge workflow URL and does not duplicate its work
through a local Backlogger run. Backlog reconciliation may repair later Project
drift from canonical Git, but it is not the primary merge transition. Record
the merge and reconciliation evidence in the human-readable factory journal.
Never close the ticket before the merged commit is confirmed.
