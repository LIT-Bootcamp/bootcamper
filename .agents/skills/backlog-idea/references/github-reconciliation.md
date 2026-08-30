# GitHub reconciliation

Use this procedure only after the skill has produced a saved preview and the human has authorized that exact operation set.

## Authorization and snapshots

1. Run `gh auth status` and verify the active token has repository access and the required project scope (`project`). Stop before mutation if either is absent.
2. Confirm the authorized repository and Bootcamper Project identifiers. Do not infer a different target.
3. Capture every issue with `gh issue list --state all --limit 1000 --json number,title,body,state,url` and every Project item with `gh project item-list ... --limit 1000 --format json`. Verify the returned counts against the corresponding repository and Project totals; paginate through the API instead when 1000 is insufficient. Capture branch and pull-request state needed to protect active implementation.
4. Feed the recorded JSON and canonical ticket hashes to `ProductFactory::GitHubPlan`. Save its deterministic preview before apply.
5. Immediately before apply, recapture issues, Project items, branches, and pull requests. Compare their hashes with the authorized snapshot. Abort, record the drift, and regenerate the preview if any reconciliation-relevant state changed.

## Issue operations

Use the exact preview attributes:

- Create with `gh issue create`; include `<!-- product-factory-ticket-id: TICKET-NNN -->` in the body.
- Update canonical title or body with `gh issue edit`.
- Close a deleted or superseded ticket with `gh issue close --reason "not planned"` only when no active branch or pull request exists.
- Reopen a canonical active ticket with `gh issue reopen`.
- Add a created or recovered issue to the Project with `gh project item-add`.

After a successful create, record the returned issue number in the TICKET manifest and journal. If a later operation fails, retain the successful mapping and record exact recovery instructions; do not replay the create.

## Project fields

The preview must contain an explicit Project-add operation before field operations whenever an issue is not already a Project item. The managed fields are `Idea`, `Epic`, `Ticket ID`, `Priority`, `Status`, `Estimate`, `Dependencies`, `Source Version`, and `Factory Run`. Resolve field and option IDs from the authorized Project. Run `gh project item-edit` for one field per invocation. Append a journal entry immediately after each successful field update with run ID, ticket ID, issue number, field, previous value, and new value.

Ignore fields outside this list. Git is authoritative for managed values, but never erase implementation evidence to repair drift.

## Completion, escalation, and retry

A recorded merged pull request requires a new immutable TICKET version in `done`, followed by dependency recalculation. Newly unblocked tickets receive valid immutable `available` versions before their Project status is updated.

Escalate rather than mutate when stable-ID markers are duplicate or ambiguous, a recorded mapping conflicts with candidates, an active branch or pull request protects a closure, authorization does not match the preview, or applying the preview fails partway through. The escalation packet lists successful operations, unapplied operations, current remote hashes, and idempotent recovery commands. Never merge a pull request.
