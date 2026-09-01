# TICKET-002 — Enforce confirmation-proof lifecycle

| Field | Value |
| --- | --- |
| Status | completed |
| Started | 2026-09-01T17:49:32Z |
| Completed | 2026-09-01T19:32:00Z |
| Implementation agent | senior_ruby_rails_engineer |

## Ticket contract

### Problem

Learners must only be able to confirm email ownership with the current valid proof, while invalid, expired, used, or superseded proofs leave private account state unchanged.

### Acceptance criteria

- [x] Valid current confirmation proof marks email ownership confirmed.
- [x] Invalid and expired confirmation proofs leave account state unchanged and render the same generic failure response.
- [x] Used and superseded confirmation proofs leave account state unchanged and render the same generic failure response.
- [x] A blocked learner can confirm with a valid proof without clearing the blocked state or restoring ordinary sign-in eligibility.

### Approved requirement clarifications

- None

## Approved plan and Q&A

### Plan

1. Review the immutable TICKET-002 contract, current confirmation controller boundary, and existing request coverage.
2. Extend focused request specs to cover the current-proof lifecycle states required by SCENARIO-004/005/006/007/008/012.
3. Re-run focused verification, lint the touched files, validate product artifacts, and prepare review-ready handoff.

### Questions and answers

| Question | Answer | Consequence |
| --- | --- | --- |
| Additional clarifications required? | None | Work stays within the immutable TICKET-002/v005 scope. |

## Worklog

| Time | Action | Evidence/result |
| --- | --- | --- |
| 2026-09-01T17:49:32Z | Claimed ticket and published implementation artifact | TICKET-002/v005 and manifest moved to `in-progress` in the fresh `origin/main` worktree. |
| 2026-09-01T19:05:00Z | Inspected current confirmation behavior | Reviewed `ConfirmationsController`, `User` confirmable behavior, confirmation views/locales, and existing request coverage. |
| 2026-09-01T19:18:00Z | Expanded lifecycle request coverage | `spec/requests/confirmations_spec.rb` now covers unknown, expired, used, and superseded proofs plus blocked-account confirmation preserving blocked sign-in rejection. |
| 2026-09-01T19:24:00Z | Simulated proof supersession in focused coverage | Rotated the stored confirmation proof in-spec so the old still-unexpired proof can be exercised as superseded without adding the out-of-scope resend UI. |
| 2026-09-01T19:29:04Z | Published immutable review artifact | TICKET-002/v006 and manifest moved to `in-review`; product validation passed on the refreshed artifact set. |
| 2026-09-01T19:32:00Z | Verified review-ready state | Focused confirmation spec, focused RuboCop, product validation, and `git diff --check` passed in the isolated PostgreSQL-backed worktree. |
| 2026-09-01T20:02:00Z | Addressed review finding on learner-facing success guidance | Confirmation success now renders a sign-in-ready message for ordinary learners and a still-blocked message for blocked learners; request coverage follows the redirect and proves both outcomes. |
| 2026-09-01T20:06:00Z | Refreshed focused verification after remediation | Focused confirmation spec and focused RuboCop passed again after the success-guidance remediation. |

## Technical decisions

### TD-1 — Keep the production code boundary unchanged and prove the lifecycle through request coverage

- Context: Devise Confirmable already enforces token lookup, confirmation expiry, and already-confirmed rejection at the confirmation boundary.
- Decision: Leave `ConfirmationsController` and `User` behavior unchanged, and strengthen request coverage to prove the required lifecycle states instead of adding duplicate confirmation logic.
- Alternatives:
  - Re-implement confirmation lifecycle checks in the controller — rejected because it would duplicate Devise policy and risk drift from the framework behavior.
  - Add only model-level tests — rejected because the ticket acceptance evidence explicitly targets request-level confirmation behavior.
- Consequences: The ticket stays minimal, the observable boundary is covered directly, and future regressions in the framework integration will surface in request specs.

### TD-2 — Simulate superseded proofs by rotating the stored token inside the spec

- Context: The resend-confirmation product surface is explicitly out of scope, but the ticket still requires evidence that an older proof cannot confirm the account once a newer proof exists.
- Decision: Rotate the persisted confirmation proof inside the request spec, then assert the previous raw proof fails with no state mutation.
- Alternatives:
  - Skip superseded-proof coverage until a resend endpoint exists — rejected because it would leave SCENARIO-008 without acceptance evidence.
  - Add a new product endpoint solely for testability — rejected as out of scope for this ticket.
- Consequences: SCENARIO-008 is covered now without expanding the user-facing surface area.

### TD-3 — Carry confirmation success guidance across the redirect with a one-request flash variant

- Context: Review found the ticket evidence did not prove the learner-facing distinction between a newly sign-in-eligible account and a still-blocked account.
- Decision: Set a flash variant during successful confirmation, then render a sign-in-ready success message for ordinary learners and a still-blocked message for blocked learners on the redirected success page.
- Alternatives:
  - Keep one static success page — rejected because it cannot satisfy the blocked-vs-unblocked user outcome described in the ticket.
  - Encode the result in query parameters — rejected because flash keeps the branch ephemeral and avoids URL-level state.
- Consequences: The request boundary still stays simple, but acceptance coverage can now prove the visible post-confirmation guidance for both account states.

## Challenges

- Devise reuses an in-memory raw confirmation token during repeated sends, so the superseded-proof example needed an explicit persisted-token rotation on a freshly loaded record.

## Verification

| Command/check | Result | Notes |
| --- | --- | --- |
| `RAILS_ENV=test ... bin/rails db:prepare` | passed | Verified connectivity and prepared the PostgreSQL-backed test database in the isolated worktree. |
| `RAILS_ENV=test ... bin/rails tailwindcss:build` | passed | Built the request-spec asset dependency for layout-backed confirmation pages. |
| `RAILS_ENV=test ... bundle exec rspec spec/requests/confirmations_spec.rb` | passed | `8 examples, 0 failures`; covers SCENARIO-004/005/006/007/008/012 including the redirected success guidance. |
| `mise exec ruby@4.0.6 -- bundle exec rubocop --cache false app/controllers/confirmations_controller.rb spec/requests/confirmations_spec.rb` | passed | 2 files inspected, no offenses detected. |
| `bin/product_factory validate --root product` | passed | Immutable TICKET-002/v006 artifact and coverage validate. |
| `git diff --check` | passed | No whitespace or conflict-marker issues. |

## Reviews

These fields remain `pending` for implementation-only use.

### Fresh-eye reviewer

- Initial verdict: APPROVED
- Findings: none
- Responses/fixes: not applicable
- Re-review verdict: not applicable

### Project-context reviewer

- Initial verdict: CHANGES REQUIRED
- Findings:
  - Medium — request evidence and success UI did not distinguish the ordinary sign-in-ready path from the still-blocked path.
  - Low — the immutable review artifact described state-specific invalid-link wording while the privacy requirement and acceptance tests relied on one generic invalid response.
- Responses/fixes:
  - Added a flash-driven success variant plus request assertions that follow the redirect and prove the visible message for both normal and blocked accounts.
  - Refreshed the immutable ticket artifact to clarify that all invalid proof states share the same generic failure message.
- Re-review verdict: APPROVE

## Lessons learned

- Devise Confirmable's request boundary can satisfy the ticket with stronger acceptance coverage when the product requirement matches framework behavior.
- Superseded confirmation proofs need a forced token rotation in tests because repeated sends reuse the current token while it remains valid.
- Redirected confirmation success pages can still carry state-specific learner guidance safely via flash without widening the route surface.

## Token consumption

| Participant/phase | Input | Output | Total | Source |
| --- | ---: | ---: | ---: | --- |
| Coordinator | unavailable | unavailable | unavailable | Runtime did not expose usage |
| senior_ruby_rails_engineer | unavailable | unavailable | unavailable | Runtime did not expose usage |

## Outcome

- Acceptance criteria: Focused request coverage proves valid-current confirmation, unchanged state for unknown/expired/used/superseded proofs, the visible success guidance for ordinary and blocked accounts, and blocked-account confirmation that still denies ordinary sign-in.
- Changed product files: `app/controllers/confirmations_controller.rb`; `app/views/confirmations/success.html.erb`; `config/locales/en.yml`; `config/locales/uk.yml`; `spec/requests/confirmations_spec.rb`.
- Remaining Minor findings/follow-ups: Dual review and lead-only release steps still remain outside this implementation-only handoff.
- Final status: ready_for_review
