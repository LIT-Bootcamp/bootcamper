# Implementation Workflow

## Start

After exact-plan approval, resume the same engineer. Create the single task record, capture the approved contract and plan, preserve unrelated changes, and establish a baseline with the narrowest relevant checks. Pre-existing failures are evidence, not ticket scope; record them and pause only when they prevent responsible implementation or verification.

## Execute

Choose verification by change type:

- **New behavior:** write a focused failing test, confirm the expected failure, implement the smallest coherent change, pass, then refactor while green.
- **Bug fix:** reproduce the defect with a failing regression test before fixing it.
- **Behavior-preserving refactor:** establish adequate characterization coverage first and keep public behavior green.
- **Configuration, infrastructure, generator, migration, or documentation:** define the most meaningful observable executable check before editing; record why an ordinary red unit test is not meaningful.

Work in small cycles and log meaningful evidence rather than every command. Stop when new information invalidates the approved plan or creates an unanswered consequential question.

## Self-Review

Before handoff, map each acceptance criterion to a test or explicit check; inspect the final product diff excluding the task record; remove debug code, unrelated edits, secrets, and accidental artifacts; perform the custom agent's impact scan; and run focused checks, the affected suite, repository lint/format, security/static analysis, schema checks, and critical browser verification in proportion to risk. Record exact results and disclose checks not run.

## Immutable Handoff

Set the task record to `ready_for_review`. Identify the product snapshot with a content-addressed Git commit/tree when available. Otherwise provide a complete binary-safe patch, a SHA-256 digest, and a manifest of changed product-file hashes. A mutable path list is insufficient. Exclude the current task record and other operational artifacts.

Return the snapshot identity, manifest, changed product paths, independent verification commands, criterion evidence, remaining risks, and record path. Any later product-code, test, configuration, migration, or user-documentation change invalidates this handoff and requires a new snapshot; task-record-only updates do not.

## Remediation

For evidence-backed findings, evaluate them against the approved plan. Fix accepted in-scope findings, run affected checks, update the worklog, and emit a new immutable snapshot. If remediation is material, remain read-only and return a revised-plan request instead.
