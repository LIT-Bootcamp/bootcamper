# Single-File Task Record

Resolve the directory from repository policy, defaulting to `docs/engineering/tasks`. Require a stable ticket ID. If it matches `[A-Za-z0-9][A-Za-z0-9._-]*`, use that ID alone as the filename, for example `E1-01.md`; otherwise create a readable sanitized slug and stop on collisions.

Create exactly one record per ticket. Redact secrets, credentials, personal data, sensitive customer/incident content, and unnecessary raw output. Append history; never erase earlier findings or decisions.

```markdown
# <TICKET-ID> — <Title>

| Field | Value |
| --- | --- |
| Status | in_progress / ready_for_review / in_review / completed / blocked |
| Started | ISO-8601 timestamp |
| Completed | pending or ISO-8601 timestamp |
| Implementation agent | senior_ruby_rails_engineer / isolated fallback |

## Ticket contract

### Problem

### Acceptance criteria

- [ ] <criterion>

### Approved requirement clarifications

- <clarification, dependency waiver, or `None`>

## Approved plan and Q&A

### Plan

1. <approved step>

### Questions and answers

| Question | Answer | Consequence |
| --- | --- | --- |

## Worklog

| Time | Action | Evidence/result |
| --- | --- | --- |

## Technical decisions

### TD-1 — <Title or `None`>

- Context:
- Decision:
- Alternatives:
- Consequences:

## Challenges

- <challenge, cause, resolution, or `None`>

## Verification

| Command/check | Result | Notes |
| --- | --- | --- |

## Reviews

These fields remain `pending` for implementation-only use. The
`deliver-rails-ticket` workflow fills them during dual review and finalization.

### Fresh-eye reviewer

- Initial verdict:
- Findings:
- Responses/fixes:
- Re-review verdict:

### Project-context reviewer

- Initial verdict:
- Findings:
- Responses/fixes:
- Re-review verdict:

## Lessons learned

- <reusable lesson or `None`>

## Token consumption

| Participant/phase | Input | Output | Total | Source |
| --- | ---: | ---: | ---: | --- |
| Coordinator | unavailable | unavailable | unavailable | Runtime did not expose usage |
| senior_ruby_rails_engineer | unavailable | unavailable | unavailable | Runtime did not expose usage |
| fresh_eye_rails_reviewer | unavailable | unavailable | unavailable | Runtime did not expose usage |
| project_context_rails_reviewer | unavailable | unavailable | unavailable | Runtime did not expose usage |

Use exact runtime telemetry when exposed; never estimate missing values. Add remediation and re-review rows when exact usage exists.

## Outcome

- Acceptance criteria:
- Changed product files:
- Remaining Minor findings/follow-ups:
- Final status:
```
