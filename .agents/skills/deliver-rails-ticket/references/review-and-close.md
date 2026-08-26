# Review and Close

## Sanitized Snapshot Packet

Build one immutable logical packet containing the ticket ID and exact acceptance criteria, approved reviewer-safe clarifications, content-addressed product snapshot and digest, changed-product-file manifest with hashes, excluded operational paths including the current task record, independent verification commands, isolated environment details, and relevant context paths only for project-context mode.

A mutable path list is not a snapshot. If any product code, test, configuration, migration, or user-documentation file changes, discard both verdicts, rebuild the snapshot, and run both reviewers again. Task-record-only changes do not invalidate the product verdict.

## Findings and Rework

Critical and Major findings block completion. Preserve every initial finding and re-review verdict in the task record.

Before remediation, compare each finding with the approved plan:

- For in-scope corrections, resume the same `senior_ruby_rails_engineer` through the remediation section of `implement-rails-ticket`.
- For material changes to behavior, architecture, dependencies, public contracts, security/privacy, data integrity, or migration strategy, obtain approval for a revised plan before editing.

After any product change, create a new immutable snapshot and have both reviewers review it. The reviewer that raised a blocking finding must explicitly verify its remediation as part of the new review.

## Finalize

After two final `APPROVE` verdicts, append reviews, responses, lessons, outcome, timestamps, and exact token telemetry to the single task record. Use `unavailable` for telemetry the runtime does not expose; never estimate. Validate required headings, acceptance checkboxes, verdicts, redaction, and final status.
