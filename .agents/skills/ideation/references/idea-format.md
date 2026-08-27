# IDEA artifact format

Publish each idea at `product/ideas/IDEA-NNN-short-slug/idea/vNNN.md`. Keep prior versions immutable. The first version is `v001.md`; later versions name their immediate predecessor and a non-empty reason.

Every IDEA version starts with the product-factory front matter required by `docs/product-factory/artifact-contract.md`: `id`, `version`, `author`, `run_id`, `created_at`, `previous_version`, `reason`, `source_versions`, `assumptions`, `unresolved_questions`, and `state: proposed`.

The Markdown body contains:

- Product problem and intended user outcome.
- Evidence with direct source links and verification dates.
- Scores from 1 to 5 for User benefit, Progressiveness, Business value, and Confidence, followed by a priority rationale rather than a score formula.
- Assumptions and unresolved questions, without architecture or implementation proposals.

Validate the version before changing `idea/manifest.yml`. The manifest points to the validated current version, state, source versions, and normalized SHA-256. Append the IDEA ID, version, run ID, and reason to `product/ideas/IDEA-NNN-short-slug/changelog.md`.

Store reusable research versions under `product/research/` with their direct source links and verification dates. Add a factory run entry under `product/factory-log/` for every invocation, including `success`, `no-op`, or `escalated`, affected IDs, and the next action.
