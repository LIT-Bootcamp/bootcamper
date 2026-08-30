---
name: documentation-analyze
description: Use when BA-ready product EPICs need technical review, clarification, ticket decomposition, dependency planning, or incremental re-analysis before backlog publication.
---

# Analyze Product Documentation

Scan all IDEA directories under `product/ideas/` for new or changed `BA-ready` EPIC versions since the last successful `documentation-analyze` run. An optional IDEA ID limits which directories are processed but does not change the incremental comparison. Start and finish the run through `bin/product_factory`; valid terminal results are `success`, `no-op`, and `escalated`.

For every actionable EPIC, spawn project-scoped `bootcamper_technical_lead` and `bootcamper_business_analyst` agents from `.codex/agents/` in isolated context with no inherited conversation. Give both agents the current IDEA and EPIC versions, Gherkin, coverage matrix, artifact contract, and [clarification protocol](../../../docs/product-factory/clarification-protocol.md).

The TL reviews completeness and sends numbered questions to the BA for at most three clarification rounds. BA alone may publish revised requirements, Gherkin, coverage, assumptions, or clarification artifacts. The TL must not edit BA-owned artifacts. After each BA revision, validate it before updating its manifest and rerun TL review against the new immutable version.

When the scenarios are sufficient, the TL alone publishes and advances manifests for:

- one versioned directory per stable TICKET using [ticket-format.md](references/ticket-format.md);
- scenario coverage mapping every Gherkin scenario to at least one ticket and every ticket to exact scenario IDs or lines;
- risks, assumptions, and external actions;
- an acyclic dependency matrix and ordered delivery waves.

Store technical coverage, risks, dependency matrix, and delivery waves in the EPIC's `analysis/technical/vNNN.md`; store escalation packets at `analysis/escalations/RUN-ID.md`. The TL owns these technical artifacts. The IDEA changelog records every published ticket and analysis version.

Tickets must have an observable result, difficulty from 1 to 5, an estimate of at most 2 ideal days, explicit dependencies, and narrow allowed scope. Split larger work. Prefer independent tickets that can run in parallel.

Validate all output with `bin/product_factory validate --root product` before changing manifests. Then publish the next immutable `TL-approved` EPIC analysis version, update manifests and changelog, and finish the run with affected IDs. If no source version or content hash changed, record `no-op` without rewriting artifacts.

On a third unresolved round or a material product, security, cost, or external-commitment ambiguity, preserve the transcript and completed work in an escalation packet. Continue other tickets and independent EPICs, but do not advance the affected EPIC to `TL-approved`. Escalate only the affected decisions and finish the mixed run as `escalated`, listing both completed and escalated IDs. Retain valid independent outputs and their source hashes so the next run treats them as unchanged rather than publishing duplicates.
