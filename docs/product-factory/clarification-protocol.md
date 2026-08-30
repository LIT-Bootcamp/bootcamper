# Product Factory clarification protocol

BA-to-Ideator and TL-to-BA clarifications use this protocol. It is a reference, not a skill.

## Round record

Each exchange records a round number, numbered questions, direct answers, `resolved` items, `open` items, and `assumptions`. Questions identify the artifact version and the decision needed; answers refer to their question number. The party asking a question never edits the other party's artifact.

```yaml
round: 1
questions:
  - id: Q1
    question: What observable outcome decides this case?
answers:
  - question_id: Q1
    answer: The user sees the saved outcome.
resolved: [Q1]
open: []
assumptions: []
```

## Ownership and versions

Only the artifact owner edits its artifact. When an answer changes an artifact, its owner publishes the next sequential version as a new immutable version, naming the immediate predecessor, change reason, source versions, assumptions, and unresolved questions. Validate the new version before updating its manifest; update `current_version` and `content_sha256` only after validation, and retain its immediate predecessor. Other participants retain their findings in the round record; they never amend an owner artifact or its manifest.

## Convergence and escalation

The conversation has a maximum of three rounds. Continue independent work when an explicit assumption does not materially change product behavior, security, cost, or an external commitment. On the third unresolved round, stop only the affected decision and create an escalation packet containing the affected artifact versions, complete transcript, resolved and open items, assumptions, completed independent work, failed rule, available choices, and exact human action required. Preserve all independent progress and mark the phase `escalated`.
