# EPIC and Gherkin format

Create each EPIC at:

`product/ideas/IDEA-NNN-short-slug/epics/EPIC-NNN-short-slug/`

The EPIC has a `manifest.yml`, immutable analysis records under `analysis/`, and exactly one versioned requirements file at:

`product/ideas/IDEA-NNN-short-slug/epics/EPIC-NNN-short-slug/requirements/vNNN.feature`

The `.feature` file begins with the product-factory version front matter from `docs/product-factory/artifact-contract.md`, using `kind: epic`, the stable EPIC ID, BA as author, source IDEA versions, assumptions, unresolved questions, and lifecycle state. Its Gherkin uses stable requirement and scenario IDs in comments:

```gherkin
# requirement_id: REQUIREMENT-001
Feature: Short EPIC outcome

  # scenario_id: SCENARIO-001
  Scenario: Happy path
    Given a relevant starting condition
    When the user performs the action
    Then the observable outcome is shown
```

Put the EPIC coverage matrix in `requirements/coverage.yml`. It maps each `requirement_id` to its `happy_path` scenario and relevant `edge_or_error` scenarios; use an empty list only when there is no relevant edge or error behavior.

```yaml
requirements:
  - requirement_id: REQUIREMENT-001
    happy_path: SCENARIO-001
    edge_or_error: [SCENARIO-002]
```

Publish only a validated new immutable version, then update the EPIC manifest's current version and normalized content hash. Append the IDEA changelog with the run ID, EPIC ID, version, and reason.
