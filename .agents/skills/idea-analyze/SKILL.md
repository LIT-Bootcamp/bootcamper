---
name: idea-analyze
description: Turn one explicitly approved proposed IDEA into BA-owned Gherkin EPICs and requirement coverage. Use only with an IDEA ID; do not use for technical design or implementation.
---

# Analyze Product Idea

Require an explicit IDEA ID. Load its IDEA manifest and reject a missing ID, a non-matching ID, or any state other than `proposed`. Start the run with `bin/product_factory start-run --root product --phase idea-analyze --source-id IDEA-ID`; retain the returned run ID.

The invocation is the human approval: record `human-approved` as the next valid immutable IDEA transition, validate it, and update the IDEA manifest only after validation. Do not treat agent output as approval.

Spawn the project-scoped `bootcamper_business_analyst` and `bootcamper_ideator` from `.codex/agents/` in isolated context with no inherited conversation. Provide the BA the approved IDEA, artifact contract, and [clarification protocol](../../../docs/product-factory/clarification-protocol.md). Provide the Ideator only the approved IDEA and BA questions. Use the BA-to-Ideator protocol for at most three clarification rounds, retaining every round record and transcript in the IDEA's `epics/*/analysis/` directories.

BA alone writes or revises EPIC, Gherkin, coverage, assumptions, and clarification artifacts. The Ideator answers BA questions but never edits BA-owned output. BA creates stable EPIC directories and one Gherkin document per EPIC as described in [epic-and-gherkin-format.md](references/epic-and-gherkin-format.md). Every requirement in `coverage.yml` maps to a happy-path scenario ID and each relevant edge or error scenario ID.

Validate outputs with `bin/product_factory validate --root product` before changing manifests. After all BA output is valid, record the next IDEA transition to `analyzed`, update the manifest, append the IDEA changelog, and finish the factory run with its affected IDs. Finish unchanged input as `no-op` where allowed.

On material product, security, cost, or external-commitment ambiguity, or on a third unresolved round, write an escalation packet with the transcript, affected artifacts, resolved and open items, assumptions, completed independent work, choices, and exact human action. Finish the run as `escalated` and retain the last valid state.
