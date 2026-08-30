---
name: backlog-idea
description: Incrementally preview and, after explicit authorization, reconcile approved Product Factory tickets with the Bootcamper GitHub Issues and Project backlog. Do not use for requirement or ticket-scope changes.
---

# Reconcile Product Backlog

Validate canonical artifacts with `bin/product_factory validate --root product`, start a `backlog-idea` factory run, and compare current TICKET manifests with the last successful run. Spawn the project-scoped `bootcamper_backlogger` from `.codex/agents/bootcamper-backlogger.toml` in isolated context with no inherited conversation. Give it only the validated manifests, recorded GitHub snapshots, run ID, repository and Project identifiers, and [the reconciliation procedure](references/github-reconciliation.md).

Build operations with the pure `ProductFactory::GitHubPlan`; do not embed `gh` execution in the planner. It uses the stable `<!-- product-factory-ticket-id: TICKET-NNN -->` issue-body marker and returns a deterministic preview sorted by Ticket ID and action. The preview includes required Project schema creation, Project membership, create, update, close superseded, reopen, unchanged no-op, managed-field repair, merged pull request completion, and escalation for ambiguous mappings or an active branch or pull request that protects implementation work.

Preview and apply are separate. Save the deterministic preview, validated local projection digest, repository base commit, and remote snapshot hashes in the append-only factory journal. Show all external mutations and require explicit human authorization for the exact repository, Project, and operation set before calling GitHub. A preview-only or unchanged run performs no GitHub mutation. Before an authorized apply, verify `gh auth status` includes project scope, revalidate local artifacts, and abort if either local or remote input changed.

Git is authoritative for issue title, body, and these Project fields: Idea, Epic, Ticket ID, Priority, Status, Estimate, Dependencies, Source Version, and Factory Run. Ignore unmanaged manual fields. Apply each Project field with one `gh project item-edit` invocation and append one journal entry for that field operation. Record stable issue numbers in ticket manifests only after the corresponding GitHub operation succeeds.

A merged pull request advances its ticket through a new immutable `done` version. Recompute dependency safety and publish newly unblocked tickets through valid immutable versions. Closing or replacing a ticket with active implementation is forbidden; escalate instead. Duplicate markers, conflicting issue mappings, missing protected mappings, unauthorized targets, and partial apply failures also escalate with completed operations and exact recovery steps preserved.

Stage each new immutable version together with its proposed manifest in a temporary product-tree copy and validate that complete candidate. Publish the validated version and manifest together; never leave the canonical tree with a version/manifest mismatch. Finish the run as `success`, `no-op`, or `escalated`, including source/output IDs, every external change, and the next action. Never change business requirements, technical scope, or merge a pull request.
