# Product Factory artifact contract

`product/` is the canonical factory root. It contains `ideas/`, `research/`, and `factory-log/`.
Ideas live in `ideas/IDEA-001-short-slug/`; its IDEA, EPIC, and TICKET directories contain immutable `v001`, `v002`, and later version files plus one `manifest.yml`. `factory-log/` contains one append-only YAML run record per `RUN-YYYYMMDDTHHMMSSZ-abcdef` ID. `research/` contains reusable source material.

Stable IDs are `IDEA-001`, `EPIC-001`, and `TICKET-001` (an uppercase kind, hyphen, and three or more digits). A manifest uses this shape:

```yaml
id: TICKET-001
kind: ticket
current_version: 2
state: available
source_versions:
  EPIC-001: 3
content_sha256: <64 lowercase hex characters>
github_issue: 42
dependencies: [TICKET-000]
priority: 1
estimate_days: 1.5
```

Version files begin with YAML front matter. Required keys are `id`, `version`, `author`, `run_id`, `created_at`, `previous_version`, `reason`, `source_versions`, `assumptions`, and `unresolved_questions`. `state` records the lifecycle state at that version so transitions can be checked.

```yaml
id: TICKET-001
version: 2
author: technical_lead
run_id: RUN-20260827T120000Z-a1b2c3
created_at: '2026-08-27T12:00:00Z'
previous_version: 1
reason: Split delivery from review after dependency analysis
source_versions:
  EPIC-001: 3
assumptions: []
unresolved_questions: []
state: available
```

Versions start at `v001`; every later version names its immediate predecessor and has a non-empty change reason. `content_sha256` is the SHA-256 of the current version file bytes after replacing CRLF with LF. A manifest can include `scenarios: [SCENARIO-001]`; `coverage.yml` uses `scenarios: [{ id: SCENARIO-001, tickets: [TICKET-001] }]`. Every coverage scenario has a ticket and every ticket has a covered scenario.

Allowed normal lifecycle transitions are:

- IDEA: `proposed -> human-approved -> analyzed`
- EPIC: `draft -> BA-ready -> TL-review -> TL-approved`
- TICKET: `draft -> backlog-ready -> available -> in-progress -> in-review -> ready-for-human-merge -> done`

`blocked`, `superseded`, and `escalated` are exceptional states. A transition may enter an exceptional state; it may leave only to the immediately preceding normal state. Ticket dependencies form an acyclic graph, and `estimate_days` is at most `2`.

A run produces immutable `RUN-ID-started.yml` and `RUN-ID-finished.yml` records. Each record includes `run_id`, `phase`, `skill`, `started_at`, `finished_at`, `source_ids`, `source_snapshot`, `output_ids`, `status`, `external_changes`, `error`, and `next_action`. Successful finished records are checkpoints for deterministic `new`, `changed`, `deleted`, `newly_unblocked`, and `unchanged` classifications.

GitHub projections map one `TICKET-ID` to one `github_issue` and carry Idea, Epic, Ticket ID, Priority, Status, Estimate, Dependencies, Source Version, and Factory Run. Git is authoritative.
