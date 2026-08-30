# GitHub reconciliation

Use this procedure only after the skill has produced a saved preview and the human has authorized that exact operation set.

## Authorization and snapshots

1. Run `gh auth status` and verify the active token has repository access and the required project scope (`project`). Stop before mutation if either is absent.
2. Confirm the authorized repository and Bootcamper Project identifiers. Do not infer a different target.
3. Capture every issue with `gh issue list --state all --limit 1000 --json number,title,body,state,url` and every Project item with `gh project item-list ... --limit 1000 --format json`. Verify the returned counts against the corresponding repository and Project totals; paginate through the API instead when 1000 is insufficient. Capture branch and pull-request state needed to protect active implementation.
4. Feed the recorded JSON and canonical ticket hashes to `ProductFactory::GitHubPlan`. Save its deterministic preview before apply.
5. Save the validated local projection digest and repository base commit alongside the remote hashes and preview.
6. Immediately before apply, revalidate the canonical artifacts and recompute the local projection digest and base commit. Recapture issues, Project fields, Project items, branches, and pull requests. Compare their hashes, including every local and remote digest, with the authorized snapshot. Abort, record the drift, and regenerate the preview if any reconciliation-relevant state changed.

## Issue operations

Use the exact preview attributes:

- Create with `gh issue create`; include `<!-- product-factory-ticket-id: TICKET-NNN -->` in the body.
- Update canonical title or body with `gh issue edit`.
- Close a deleted or superseded ticket with `gh issue close --reason "not planned"` only when no active branch or pull request exists.
- Reopen a canonical active ticket with `gh issue reopen`.
- Add a created or recovered issue to the Project with `gh project item-add`.

After a successful create, record the returned issue number in the TICKET manifest and journal. If a later operation fails, retain the successful mapping and record exact recovery instructions; do not replay the create.

## Project fields

Before planning item changes, capture the complete field connection with `gh api graphql`. Query `totalCount`, page cursors, and nodes containing `id`, `name`, `__typename`, `dataType` for `ProjectV2Field`, and option `id`/`name` for `ProjectV2SingleSelectField`. Follow `pageInfo.endCursor` until `hasNextPage` is false, then store a normalized `project_fields` hash with `totalCount` and all `nodes`. Do not use `gh project field-list --format json` as planner input because its generic field type does not preserve text-versus-number data types.

The planner verifies `totalCount`, normalizes GraphQL `dataType`, maps `ProjectV2SingleSelectField` to `SINGLE_SELECT`, and normalizes option objects by name. The preview must include one schema operation for every missing managed field and an explicit Project-add operation before field operations whenever an issue is not already a Project item. Escalate an incomplete field snapshot, a same-name field with an incompatible type, or an incompatible `Status` option set.

Create missing fields with `gh project field-create`, using text for `Idea`, `Epic`, `Ticket ID`, `Dependencies`, and `Factory Run`; number for `Priority`, `Estimate`, and `Source Version`; and single-select for `Status` with all factory lifecycle values. Journal every schema mutation. The managed fields are `Idea`, `Epic`, `Ticket ID`, `Priority`, `Status`, `Estimate`, `Dependencies`, `Source Version`, and `Factory Run`.

Resolve field and option IDs from the authorized Project only after the schema operations succeed. Run `gh project item-edit` for one field per invocation. Append a journal entry immediately after each successful field update with run ID, ticket ID, issue number, field, previous value, and new value.

Ignore fields outside this list. Git is authoritative for managed values, but never erase implementation evidence to repair drift.

## Completion, escalation, and retry

A recorded merged pull request requires a new immutable TICKET version in `done`, followed by dependency recalculation. Newly unblocked tickets receive valid immutable `available` versions before their Project status is updated.

Escalate rather than mutate when stable-ID markers are duplicate or ambiguous, a recorded mapping conflicts with candidates, an active branch or pull request protects a closure, authorization does not match the preview, or applying the preview fails partway through. The escalation packet lists successful operations, unapplied operations, current remote hashes, and idempotent recovery commands. Never merge a pull request.
