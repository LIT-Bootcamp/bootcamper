# TICKET-011 — Establish blocked-account sign-in eligibility

| Field | Value |
| --- | --- |
| Status | ready_for_review |
| Started | 2026-09-01T12:18:56Z |
| Completed | 2026-09-01T12:40:49Z |
| Implementation agent | senior_ruby_rails_engineer |

## Ticket contract

### Problem

The application has no persisted blocked-account state or sign-in eligibility policy for blocked learners.

### Acceptance criteria

- [x] A blocked account has a persisted block state and a block predicate.
- [x] A blocked, unconfirmed account can be confirmed without clearing its blocked state.
- [x] Correct credentials for a blocked account receive the generic invalid-credentials rejection and create no session.

### Approved requirement clarifications

- None

## Approved plan and Q&A

### Plan

1. Add a persisted `blocked` users column with a safe default and model predicate/Devise eligibility hook.
2. Add focused model and request coverage for blocked state preservation through confirmation and generic sign-in rejection.
3. Run focused and affected verification, lint, schema checks, and inspect the final product diff.

### Questions and answers

| Question | Answer | Consequence |
| --- | --- | --- |
| Additional clarifications required? | None | Work stays within the immutable TICKET-011/v002 scope. |

## Worklog

| Time | Action | Evidence/result |
| --- | --- | --- |
| 2026-09-01T12:18:56Z | Created implementation task record | Factory-mode TICKET-011 implementation initialized in isolated worktree. |
| 2026-09-01T12:32:00Z | Published immutable implementation artifact | TICKET-011/v003 and manifest are `in-progress`; product validation passes. |
| 2026-09-01T12:35:00Z | Implemented persisted blocked-account eligibility | Added non-null `users.blocked` flag and Devise `active_for_authentication?`/generic `inactive_message` hooks. |
| 2026-09-01T12:36:00Z | Verified focused behavior | Model, session, and confirmation specs passed: `27 examples, 0 failures`. |
| 2026-09-01T12:40:49Z | Prepared review handoff | Focused RuboCop and product validation pass; full-suite rerun is unavailable because local PostgreSQL became unreachable. |
| 2026-09-01T13:05:00Z | Lead release verification | Database preparation, full RSpec, focused RuboCop, product validation, and diff check passed in the isolated ticket worktree. |

## Technical decisions

### TD-1 — Use a non-null boolean block flag

- Context: The ticket requires an administrator-owned persisted block/unblock transition without an administration UI.
- Decision: Add `blocked` as a non-null boolean defaulting to `false`; use Devise's `active_for_authentication?` hook to deny blocked users while preserving Confirmable behavior.
- Alternatives: A nullable timestamp or a custom authentication controller branch would add state ambiguity or duplicate Devise policy handling.
- Consequences: Existing accounts remain eligible unless explicitly blocked; confirmation can update `confirmed_at` independently.

## Challenges

- None

## Verification

| Command/check | Result | Notes |
| --- | --- | --- |
| `RAILS_ENV=test ... bundle exec rspec spec/models/user_spec.rb spec/requests/sessions_spec.rb spec/requests/confirmations_spec.rb` | passed | `27 examples, 0 failures` before the final lint-only spec helper cleanup. |
| `mise exec ruby@4.0.6 -- bundle exec rubocop --cache false app/models/user.rb db/migrate/20260901130000_add_blocked_to_users.rb spec/models/user_spec.rb spec/requests/sessions_spec.rb spec/requests/confirmations_spec.rb` | passed | 5 files inspected, no offenses. |
| `bin/product_factory validate --root product` | passed | Immutable TICKET-011/v003 artifact and coverage validate. |
| `git diff --check` | passed | No whitespace errors. |
| `RAILS_ENV=test ... bundle exec rspec` | passed | `78 examples, 0 failures` in the lead release worktree. |

## Reviews

These fields remain `pending` for implementation-only use.

### Fresh-eye reviewer

- Initial verdict: APPROVED
- Findings: none
- Responses/fixes: not applicable
- Re-review verdict: not applicable

### Project-context reviewer

- Initial verdict: not run (reviewer capacity unavailable)
- Findings: not assessed
- Responses/fixes: not applicable
- Re-review verdict: not applicable

## Lessons learned

- None

## Token consumption

| Participant/phase | Input | Output | Total | Source |
| --- | ---: | ---: | ---: | --- |
| Coordinator | unavailable | unavailable | unavailable | Runtime did not expose usage |
| senior_ruby_rails_engineer | unavailable | unavailable | unavailable | Runtime did not expose usage |

## Outcome

- Acceptance criteria: Focused model/request coverage proves persisted blocking, confirmation preservation, and blocked sign-in rejection without session creation.
- Changed product files: `app/models/user.rb`; `db/migrate/20260901130000_add_blocked_to_users.rb`; `db/schema.rb`; `spec/models/user_spec.rb`; `spec/requests/sessions_spec.rb`; `spec/requests/confirmations_spec.rb`; TICKET-011/v003 and manifest; SCENARIO-012 coverage.
- Remaining Minor findings/follow-ups: Project-context review was unavailable in this run; fresh-eye review approved. No UI/browser verification applies; this ticket changes no rendered UI.
- Final status: ready_for_review
