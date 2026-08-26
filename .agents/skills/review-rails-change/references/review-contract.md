# Review Contract

The coordinator supplies a sanitized logical packet. It may be a prompt payload rather than a repository file. It must exclude the current operational task record even when that record appears in the working-tree diff.

Required fields:

```text
mode: fresh-eye | project-context
agent: fresh_eye_rails_reviewer | project_context_rails_reviewer
ticket_id: <stable ID>
acceptance_criteria:
  - <exact criterion>
approved_requirement_clarifications:
  - <review-safe clarification or None>
product_snapshot: <content-addressed Git commit/tree, or complete binary-safe patch>
snapshot_digest: <Git object ID or SHA-256 of patch>
changed_file_manifest:
  - <path and content hash>
excluded_paths:
  - <current task record>
verification_commands:
  - <command reviewer should run independently>
context_paths: [] # populated only for project-context mode; cannot overlap excluded paths
verification_environment: <isolated worktree/test DB/temp paths, or serialized execution instruction>
```

The reviewer must confirm that excluded paths are not part of the reviewed product diff or context paths. Reject a context directory that contains an excluded path. If a supplied broad diff includes an excluded file, ignore that file rather than reading it. If the remaining product snapshot cannot be identified without reading excluded material, return `BLOCKED`.

Verify the snapshot digest and changed-file manifest before and after review commands. A mutable path list without content hashes is not a valid snapshot. If a tracked product file changes, return `BLOCKED` for that snapshot and request a new packet.

Never include credentials, secrets, personal data, sensitive customer/incident details, raw private messages, or unnecessary production data. Ask for a redacted packet if sensitive content is necessary to state the problem.

The verdict is bound to this snapshot. Any later product code, test, configuration, migration, or user-documentation change invalidates both reviewers' verdicts and requires both to review the same new snapshot. Updates limited to the excluded operational task record do not invalidate the product verdict.
