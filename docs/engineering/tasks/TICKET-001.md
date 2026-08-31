# TICKET-001 — Make registration privacy-preserving

| Field | Value |
| --- | --- |
| Status | in_review |
| Started | 2026-08-31T16:54:29Z |
| Completed | 2026-08-31T17:08:44Z |
| Implementation agent | senior_ruby_rails_engineer |

## Ticket contract

### Problem
Visitors can create a learner account without exposing whether another account already uses the submitted email.

### Acceptance criteria
- [x] Valid registration creates one inactive learner and shows the check-email acknowledgement.
- [x] Invalid email or password creates no account and shows actionable field-level corrections.
- [x] Duplicate email creates no second account and returns the same visible acknowledgement as successful registration.

### Approved requirement clarifications
- None

## Approved plan and Q&A

### Plan
1. Inspect the existing registration flow, model constraints, routes, views, and request/model specs against the immutable ticket scope.
2. Add or adjust focused request/model coverage to prove successful, invalid, and duplicate registration behavior.
3. Implement the smallest registration-boundary changes needed to make duplicate registration privacy-preserving while keeping invalid submissions actionable.
4. Run focused verification, self-review the diff excluding this task record, and prepare an immutable review handoff.

### Questions and answers
| Question | Answer | Consequence |
| --- | --- | --- |
| Additional clarifications required? | None | Work stays within the immutable ticket scope. |

## Worklog

| Time | Action | Evidence/result |
| --- | --- | --- |
| 2026-08-31T16:54:29Z | Created implementation task record | Factory-mode TICKET-001 implementation initialized in isolated worktree. |
| 2026-08-31T16:55:10Z | Inspected registration boundary before changes | Reviewed ticket/epic requirements, routes, `RegistrationsController`, `User`, registration views/locales, and `spec/requests/registrations_spec.rb`. |
| 2026-08-31T16:56:20Z | Unblocked focused request-spec execution in the clean worktree | Trusted the worktree `mise.toml`, used the existing non-logged test credentials via `RAILS_MASTER_KEY`, and built the missing Tailwind asset after request rendering initially failed on `tailwind.css` lookup. |
| 2026-08-31T16:57:12Z | Rewrote focused coverage to the ticket contract | Registration request spec now expects duplicate-email submissions to reuse the success acknowledgement, asserts no second account, and covers the mixed duplicate+invalid-password privacy case. |
| 2026-08-31T16:58:02Z | Implemented the initial privacy-preserving duplicate-registration fix | `RegistrationsController#create` redirected duplicate-only submissions to the success page, stripped only the duplicate-email disclosure when other field errors remained, and treated the `users.email` unique-index race as the same acknowledgement path. |
| 2026-08-31T17:01:36Z | Addressed remediation round 1 timing-side-channel finding | Reworked registration confirmation delivery so the request path only enqueues a background job; duplicate-only submissions enqueue the same job type without sending another confirmation. |
| 2026-08-31T17:07:58Z | Addressed remediation round 2 commit-visibility finding | Set `RegistrationConfirmationJob.enqueue_after_transaction_commit = true` and added a dedicated non-transactional job spec that proves the job is invisible while the surrounding transaction is open and only becomes enqueued after commit. |
| 2026-08-31T17:08:44Z | Re-verified, linted, and refreshed the handoff | Focused request+job specs, focused RuboCop, and `git diff --check` passed after remediation; browser verification remained blocked because no browser control is available in this runtime. |
| 2026-08-31T17:25:28Z | Cleared release verification blocker | Confirmed local PostgreSQL availability, then passed `db:prepare`, full `bin/quality`, and full `bundle exec rspec` for lead-only release readiness. |

## Technical decisions

### TD-1 — Keep duplicate-only responses visually identical while preserving actionable non-email validation errors

- Context: The registration flow must not disclose whether an email already exists, but password and confirmation problems must still be correctable.
- Decision: Duplicate-only submissions still redirect to `registration_success_path`, while mixed invalid submissions re-render with the duplicate-email validation removed and other field errors intact.
- Alternatives:
  - Pre-check for an existing email before save — rejected because it adds an avoidable check-then-write race and a separate existence branch.
  - Return the generic success page for any submission that includes a duplicate email — rejected because it would hide actionable password/confirmation corrections.
- Consequences: Successful and duplicate-only registration attempts share the same visible acknowledgement, and mixed invalid submissions remain fixable without disclosing account existence.

### TD-2 — Move confirmation delivery work out of the request path

- Context: Review found that even with identical rendered responses, a brand-new registration still performed synchronous confirmation-mail work while a duplicate registration returned immediately, leaving a timing side channel.
- Decision: Add `RegistrationConfirmationJob` and have the controller enqueue confirmation work after both successful and duplicate-only submissions; only newly created accounts send confirmation when the job runs.
- Alternatives:
  - Send confirmation mail synchronously for duplicates too — rejected because it would spam existing addresses and blur the boundary with the later confirmation-resend ticket.
  - Use `deliver_later` directly on Devise mail notifications — rejected because Active Job logging would expose confirmation-token arguments unless broader mailer plumbing changed.
- Consequences: Request-time behavior no longer differs by synchronous mail delivery cost, new accounts still receive confirmation mail, duplicates do not trigger another confirmation message, and the job only carries a user id plus a boolean flag rather than raw tokens.

### TD-3 — Defer the confirmation job until after commit and prove that behavior outside transactional fixtures

- Context: Review found the background job could be enqueued before a surrounding transaction became visible to other connections, and the existing request spec could not prove after-commit behavior because transactional fixtures keep the outer example transaction open.
- Decision: Set `self.enqueue_after_transaction_commit = true` on `RegistrationConfirmationJob` and move enqueue-timing coverage into a dedicated non-transactional job spec.
- Alternatives:
  - Keep timing assertions in the request spec — rejected because transactional fixtures would hide the enqueue-until-commit boundary being reviewed.
  - Enqueue from a model callback — rejected as a broader refactor than needed for this ticket and awkward for the duplicate-only controller path.
- Consequences: Successful registration no longer risks losing confirmation work before commit visibility, and the spec suite now has focused evidence that would fail if the job became runnable before commit.

## Challenges

- Clean worktree request specs could not render the registration pages until `tailwind.css` was built for the asset pipeline.
- Browser verification is still blocked in this environment because no Chrome or in-app browser control tool is available; this handoff does **not** claim UI verification.
- Transactional request specs are the wrong boundary for asserting after-commit job deferral, so that coverage had to move into a dedicated non-transactional job spec.

## Verification

| Command/check | Result | Notes |
| --- | --- | --- |
| `RAILS_ENV=test RAILS_MASTER_KEY="$(cat /Users/Denys_Zemlianoi/projects/bootcamper/config/credentials/test.key)" mise exec ruby@4.0.6 -- bin/rails db:prepare` | passed | Verified successfully once the local PostgreSQL service was confirmed reachable. |
| `RAILS_ENV=test RAILS_MASTER_KEY="$(cat /Users/Denys_Zemlianoi/projects/bootcamper/config/credentials/test.key)" mise exec ruby@4.0.6 -- bundle exec rspec` | passed | `72 examples, 0 failures` after PostgreSQL became reachable. |
| `mise trust /private/tmp/bootcamper-implement-TICKET-001-rerun/mise.toml` | passed | Required once so pinned Ruby 4.0.6 commands could run in the isolated worktree. |
| `export RAILS_ENV=test; export RAILS_MASTER_KEY="$(cat /Users/Denys_Zemlianoi/projects/bootcamper/config/credentials/test.key)"; mise exec ruby@4.0.6 -- bin/rails tailwindcss:build` | passed | Built the missing `tailwind.css` asset needed for request-spec page rendering in the clean worktree. |
| `export RAILS_MASTER_KEY="$(cat /Users/Denys_Zemlianoi/projects/bootcamper/config/credentials/test.key)"; mise exec ruby@4.0.6 -- bundle exec rspec spec/requests/registrations_spec.rb spec/jobs/registration_confirmation_job_spec.rb` | passed | `8 examples, 0 failures`. Focused coverage now proves visible registration behavior plus after-commit enqueue timing for confirmation delivery. |
| `mise exec ruby@4.0.6 -- bundle exec rubocop --cache false app/controllers/registrations_controller.rb app/jobs/registration_confirmation_job.rb spec/requests/registrations_spec.rb spec/jobs/registration_confirmation_job_spec.rb` | passed | `4 files inspected, no offenses detected`. |
| `git diff --check` | passed | No whitespace or conflict-marker issues in the final diff. |
| Browser verification of affected registration UI at desktop/mobile breakpoints | blocked | UI-affecting ticket, but this runtime exposes no browser control tool, so I could not perform the mandatory visual verification. |

## Reviews

These fields remain `pending` for implementation-only use. The
`deliver-rails-ticket` workflow fills them during dual review and finalization.

### Fresh-eye reviewer

- Initial verdict: CHANGES REQUIRED
- Findings:
  - Medium — duplicate-only registration skipped synchronous confirmation work and left a measurable request-time timing side channel.
- Responses/fixes:
  - Remediation round 1 moved confirmation work to `RegistrationConfirmationJob`, making new and duplicate-only requests enqueue the same job type.
  - Remediation round 2 set `enqueue_after_transaction_commit = true` and added dedicated job coverage for the after-commit boundary.
- Re-review verdict: APPROVE

### Project-context reviewer

- Initial verdict: CHANGES REQUIRED
- Findings:
  - Medium — duplicate-only registration skipped synchronous confirmation work and left a measurable request-time timing side channel.
- Responses/fixes:
  - Remediation round 1 moved confirmation work to `RegistrationConfirmationJob`, making new and duplicate-only requests enqueue the same job type.
  - Remediation round 2 set `enqueue_after_transaction_commit = true` and added dedicated job coverage for the after-commit boundary.
- Re-review verdict: APPROVE

## Lessons learned

- Clean worktrees need an explicit Tailwind build before request specs can render layout-backed pages through Propshaft.
- Devise confirmation mail should not be sent synchronously from the registration request when privacy depends on indistinguishable request timing.
- Active Job confirmation work that depends on a freshly-created record should opt into after-commit enqueueing and carry an explicit spec for that boundary.
- After-commit job behavior needs a non-transactional spec boundary when the default request-spec transaction would otherwise mask commit timing.

## Token consumption

| Participant/phase | Input | Output | Total | Source |
| --- | ---: | ---: | ---: | --- |
| Coordinator | unavailable | unavailable | unavailable | Runtime did not expose usage |
| senior_ruby_rails_engineer | unavailable | unavailable | unavailable | Runtime did not expose usage |
| fresh_eye_rails_reviewer | unavailable | unavailable | unavailable | Runtime did not expose usage |
| project_context_rails_reviewer | unavailable | unavailable | unavailable | Runtime did not expose usage |

## Outcome

- Acceptance criteria:
  - Valid registration creates one inactive learner, leaves the visitor signed out, shows the check-email acknowledgement, and defers confirmation delivery safely until after commit.
  - Invalid registration still returns field-level validation feedback.
  - Duplicate registration returns the same visible success acknowledgement, creates no second account, hides duplicate-email disclosure, and no longer differs by synchronous confirmation-mail work in the request path.
- Changed product files:
  - `app/controllers/registrations_controller.rb`
  - `app/jobs/registration_confirmation_job.rb`
  - `spec/requests/registrations_spec.rb`
  - `spec/jobs/registration_confirmation_job_spec.rb`
- Remaining Minor findings/follow-ups:
  - Mandatory browser verification for this UI-affecting change still needs to be completed in an environment with Chrome or equivalent browser control.
- Final status:
  - in_review
  - claim_run_id: `RUN-20260831T165115Z-911e5f`
  - immutable ticket: `product/ideas/IDEA-009-account-access-recovery/epics/EPIC-001-register-and-verify-account/tickets/TICKET-001-private-registration/v003.md`
  - manifest: `product/ideas/IDEA-009-account-access-recovery/epics/EPIC-001-register-and-verify-account/tickets/TICKET-001-private-registration/manifest.yml`
  - worktree: `/private/tmp/bootcamper-implement-TICKET-001-rerun`
