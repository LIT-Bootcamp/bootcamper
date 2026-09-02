# Ticket selection and recovery

## Selection invariants

Run validation and allocate the implementation run before selection. `bin/product_factory next-ticket` is the only selector: it returns the highest-priority `available` ticket whose dependencies are satisfied, then acquires a per-ticket claim lock under the shared Git common directory. The lock is shared by every worktree for the repository.

Before new selection, inspect open pull requests targeting `main` for exact Product Factory ticket markers. An eligible active pull request has priority; claim that stable ID with `next-ticket --ticket TICKET-ID`. If multiple eligible active tickets exist, use the same priority-then-ID order. Duplicate active pull requests for one ticket are ambiguous and must escalate. Do not create a second branch or pull request; resume the existing PR branch and recovery evidence.

Use the returned ticket ID and manifest path exactly. One invocation may claim and deliver only that ticket. Do not substitute a nearby ticket when selection is empty, ambiguous, or loses a claim race.

The command outcomes are:

- exit `0`: JSON identifies the claimed ticket and manifest;
- exit `3`: no selectable ticket; finish the run as `no-op`;
- exit `4`: another run owns the claim; finish as `escalated`;
- any other non-zero exit: preserve the error and finish as `escalated`.

## Isolation order

The required order is claim, then isolation:

1. derive a collision-resistant branch name from the stable ticket ID and run ID;
2. create a separate ticket branch and worktree from the intended base;
3. move the unfinished started run record from the coordinator product root to the ticket worktree with `bin/product_factory move-run`, verifying the destination bytes before the source is removed; the command is restart-safe for an identical partial copy and rejects any already-finished run;
4. record both names and the absolute worktree path in the run evidence;
5. make product, application, test, task-record, and remaining factory-run changes only in that worktree.

Before delivery, re-read the selected manifest in the worktree. If it no longer matches the claimed `available` version or its dependencies are no longer satisfied, do not repair history or select a replacement. Preserve the worktree, release the transient claim, and escalate with the observed versions.

## Lifecycle publication

Each lifecycle change creates a new immutable ticket version rather than editing the prior version. Publish `in-progress` before implementation, `in-review` before independent review, and `ready-for-human-merge` only after the pull request exists and all factory delivery gates pass. Each version names its immediate predecessor, run ID, author, source versions, state, and non-empty reason. Validate the proposed version and manifest together in a temporary product-tree copy, then publish both together before changing the changelog.

The final `ready-for-human-merge` version is part of the implementation pull request. Commit and push it to the same branch, then verify the remote pull request head contains the version and manifest before finishing. This guarantees that, after human merge, the canonical base branch can read the exact predecessor required by post-merge completion.

## Cleanup and recovery

Always attempt to release the transient claim after a claim was acquired:

`bin/product_factory release-ticket --root product --run-id RUN-ID --ticket TICKET-ID`

Release the transient claim after successful handoff and after failed or escalated delivery. Claim release does not authorize branch deletion, worktree deletion, reset, checkout over local changes, or any other destructive cleanup.

Preserve a failed worktree and its branch for diagnosis. The finished run must record:

- ticket ID and run ID;
- branch and absolute worktree path;
- current lifecycle version and state;
- last completed delivery gate and failed command;
- whether claim release succeeded;
- exact recovery instructions and safe commands;
- the person or skill that should resume the work.

If the release command fails, do not claim that cleanup succeeded. Record the exact command for an operator to retry from the repository root and finish the run as `escalated`. If a clean successful worktree is later removed, use normal non-forced Git worktree operations only after the pull request and recovery data are durable.
