# Technical ticket format

Store each immutable version at:

`product/ideas/IDEA-NNN-short-slug/epics/EPIC-NNN-short-slug/tickets/TICKET-NNN-short-slug/vNNN.md`

Its manifest identifies the stable ticket ID, current version, lifecycle state, content hash, predecessor, source versions, author agent, run ID, creation time, change reason, assumptions, and unresolved questions.

## Required ticket body

```markdown
# TICKET-NNN: Short outcome

## Observable goal

## Source IDEA, EPIC, version, and scenario IDs

## Acceptance evidence

## Dependencies

## Difficulty (1-5)

## Estimate (ideal days, at most 2)

## Risks

## External actions

## Allowed scope
```

Use exact Gherkin scenario IDs or line references. Acceptance evidence states what a reviewer can observe or execute. Dependencies contain stable ticket IDs or `none`; external actions name work the delivery team cannot perform. Split any ticket estimated above two ideal days before publication.
