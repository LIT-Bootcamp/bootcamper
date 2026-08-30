---
name: implement
description: Claim and deliver the next dependency-safe Product Factory ticket through the existing Rails delivery workflow. Use for one automated backlog selection per invocation; do not use for a user-selected ordinary ticket or to merge a pull request.
---

# Implement Next Product Ticket

Deliver exactly one ticket per invocation. Git artifacts remain canonical, the shared claim prevents concurrent delivery of the same ticket, and every terminal outcome is recorded as `success`, `no-op`, or `escalated`. Read [ticket-selection.md](references/ticket-selection.md) before selecting, isolating, or cleaning up work.

## Validate and Claim

From the factory repository root:

1. Run `bin/product_factory validate --root product`. Stop without artifact mutation if validation fails.
2. Allocate the run ID with `bin/product_factory start-run --root product --phase implement`.
3. Run `bin/product_factory next-ticket --root product --run-id RUN-ID` once. This chooses the highest-priority available ticket whose dependencies are satisfied and acquires its claim lock in the shared Git common directory.
4. The workflow must claim before creating a branch or worktree. Do not process a second ticket in the same run.

If `next-ticket` returns exit status 3, finish the run as `no-op` and report that no ticket is available. Treat an ambiguous result, claim conflict, invalid lineage, or other selection failure as `escalated`; do not silently choose another ticket.

## Publish the Delivery State

After the claim succeeds, create a separate ticket branch and worktree as described in the reference. In that worktree, read the selected manifest and immutable ticket body, its source EPIC and IDEA versions, dependencies, and acceptance evidence. Verify that the IDEA is `analyzed`, the EPIC is `TL-approved`, the ticket is `available`, and all dependencies remain satisfied.

Publish a new immutable ticket version with state `in-progress`, the immediate predecessor, this run ID, and a non-empty reason. Validate the new version before updating the manifest and changelog.

Invoke the project-local `deliver-rails-ticket` skill in factory mode with this packet:

```yaml
factory_mode: true
ticket_state: in-progress
claim_run_id: RUN-ID
idea_state: analyzed
epic_state: TL-approved
dependencies_satisfied: true
```

The immutable ticket version is the approved scope boundary. Delivery must use the existing `senior_ruby_rails_engineer`, `fresh_eye_rails_reviewer`, and `project_context_rails_reviewer` agents in their required isolated contexts. Preserve both independent reviews, lead-only release commands, and at most three remediation rounds. Escalate rather than expanding scope, waiving consequential ambiguity, or continuing after a third unsuccessful remediation round.

Publish and validate an `in-review` version before independent review begins. After both reviewers approve and the lead creates the pull request, publish and validate the next immutable ticket version at `ready-for-human-merge`. Record the pull request and verification evidence in the factory run. Never merge automatically: Product Factory delivery has a human-only merge gate.

## Release and Finish

Attempt `bin/product_factory release-ticket --root product --run-id RUN-ID --ticket TICKET-ID` on success or failure after a claim was acquired.

- Finish `success` only after the pull request exists, the ticket is `ready-for-human-merge`, and the transient claim is released.
- Finish `no-op` only when selection reported no available ticket.
- Finish `escalated` for delivery, validation, publication, review, release, or cleanup failures. Include the ticket ID, branch, worktree path, last valid artifact version, completed checks, error, and next action.

Use `bin/product_factory finish-run --root product --run-id RUN-ID --status STATUS`, adding the ticket as `--output-id TICKET-ID`, the pull request as an external change when one exists, and the preserved error when escalated.

Do not use destructive cleanup. Preserve a failed worktree for diagnosis and log its worktree path. When cleanup or claim release cannot finish, record exact recovery instructions, including the directory from which to run them and the full safe command. Never delete an unmerged branch, reset files, or discard unrelated edits.
