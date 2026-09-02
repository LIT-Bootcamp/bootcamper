---
name: control-bootcamper-delivery
description: Audit and improve Bootcamper agent delivery runs using evidence, metrics, dependency checks, and an append-only control log.
---

# Control Bootcamper Delivery

Use the project-scoped `bootcamper_delivery_controller` agent for an independent delivery audit. The controller is read-only and must not replace implementation, review, or release ownership.

## Audit inputs

Provide the ticket ID, task record, immutable product snapshot/manifest, agent status history, git/branch state, CI run URLs or summaries, review verdicts, and the approved architecture context. If an input is missing, record it as unknown.

## Required checks

- Confirm the ticket contract, dependencies, and scope were stable.
- Measure elapsed time and phase durations; count retries, blockers, and failed checks.
- Verify branch → commit → PR → review/skip → merge workflow.
- Compare changed files with the handoff manifest and detect scope drift.
- Classify review findings as Critical, Major, Minor, or question; track reopened findings.
- Identify safe independent batches only when dependencies and file ownership are explicit.
- Record all evidence and corrective actions in `docs/engineering/agent-control-log.md`.
- Name the responsible agent or automation component for every violation. Never report passive labels such as “mistakenly” or “state drift” without an owner.

## Output

Return green/yellow/red health, a compact metric table, evidence-backed violations with `responsible_component`, the largest process improvement, and one next action. Never mark unknown telemetry as passing. Escalate missing authority, unsafe release actions, or contradictory plans to the coordinator.
