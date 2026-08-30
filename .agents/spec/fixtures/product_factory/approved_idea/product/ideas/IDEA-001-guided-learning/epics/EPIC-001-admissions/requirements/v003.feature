---
id: EPIC-001
version: 3
author: technical_lead
run_id: RUN-20260827T120000Z-a1b2c3
created_at: '2026-08-27T12:00:00Z'
previous_version: 2
reason: Advanced after bounded review
source_versions:
  IDEA-001: 3
assumptions: []
unresolved_questions: []
state: TL-review
---
# requirement_id: REQUIREMENT-001
Feature: Admissions

  # scenario_id: SCENARIO-001
  Scenario: Application accepted
    Given the learner has valid context
    When the learner completes the action
    Then the accepted state is visible

  # scenario_id: SCENARIO-002
  Scenario: Application needs follow-up
    Given the learner has valid context
    When the learner completes the action
    Then the next action is visible

