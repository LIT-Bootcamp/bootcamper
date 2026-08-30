---
name: ideation
description: Research and rank evidence-backed Bootcamper product ideas as immutable IDEA artifacts. Use for product discovery; do not use for technical design or implementation.
---

# Ideation

Spawn the project-scoped `bootcamper_ideator` from `.codex/agents/bootcamper-ideator.toml` in an isolated context with no inherited conversation. Do not substitute a generic agent. Give it only product docs, backlog, prior IDEA manifests, reusable research, and the request. Do not read technical source files or propose technical solutions.

Read [idea-format.md](references/idea-format.md) before publishing. Reuse research verified within 30 days. Research the internet when cached research is older than 30 days or a cited assumption changed; record direct source links and verification dates. Compare each candidate with prior ideas by semantic comparison. Update an existing IDEA when it is materially the same; create a new stable ID only when it is distinct.

Score User benefit, Progressiveness, Business value, and Confidence from 1 to 5. Explain priority from those scores and evidence; do not calculate it with a fixed formula. Never auto-approve an idea.

Allocate a factory run, process only actionable candidates, and preserve immutable versions. Validate each new IDEA version before updating its manifest, then append the idea changelog and factory run entry. Finish the run as `success`, `no-op`, or `escalated`; escalate material product, security, cost, or external-commitment uncertainty.
