---
id: EPIC-002
version: 4
author: technical_lead
run_id: RUN-20260827T120000Z-a1b2c3
created_at: '2026-08-27T12:00:00Z'
previous_version: 3
reason: Advanced after bounded review
source_versions:
  IDEA-001: 3
assumptions: []
unresolved_questions: []
state: TL-approved
---
# requirement_id: REQUIREMENT-002
Feature: Learning

  # scenario_id: SCENARIO-003
  Scenario: Legacy path removed
    Given the learner has valid context
    When the learner completes the action
    Then the superseded path is unavailable

  # scenario_id: SCENARIO-004
  Scenario: Legacy path remains explained
    Given the learner has valid context
    When the learner completes the action
    Then the replacement path is visible

