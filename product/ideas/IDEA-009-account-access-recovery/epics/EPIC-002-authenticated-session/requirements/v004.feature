---
id: EPIC-002
kind: epic
version: 4
author: bootcamper_technical_lead
run_id: RUN-20260830T203654Z-69a65e
created_at: '2026-08-30T20:36:54Z'
previous_version: 3
reason: Approve unchanged requirements after completed technical analysis and ticket decomposition
source_versions:
  IDEA-009: 3
  EPIC-002: 1
assumptions:
  - Email is the sole sign-in identifier.
  - Email confirmation is required before ordinary sign-in.
  - Inactive means created but not email-confirmed.
  - Administrative blocking overrides confirmation and credential state.
  - Block and unblock administration is outside this EPIC.
unresolved_questions: []
state: TL-approved
---
Feature: Start and end an authenticated session

  # requirement_id: REQUIREMENT-006
  # scenario_id: SCENARIO-013
  Scenario: An eligible learner signs in
    Given a confirmed and unblocked learner account exists
    When the learner submits its email and correct password
    Then an authenticated session starts
    And the learner enters the ordinary signed-in experience

  # scenario_id: SCENARIO-014
  Scenario: Sign-in credentials are incorrect
    Given a visitor is not authenticated
    When the visitor submits credentials that do not establish access
    Then no authenticated session starts
    And the response does not identify whether the email or password was wrong
    And recovery is offered as the next action

  # scenario_id: SCENARIO-015
  Scenario: An inactive learner attempts sign-in
    Given a learner account exists but its email is unconfirmed
    When the learner submits the correct email and password
    Then no authenticated session starts
    And the learner is told that confirmation is required
    And confirmation resend is offered directly
    And confirmation resend remains available through the public email form

  # scenario_id: SCENARIO-016
  Scenario: A blocked learner attempts sign-in
    Given an administrator has blocked a learner account
    When credentials for that account are submitted
    Then no authenticated session starts
    And the response matches the generic invalid-credentials response for an unknown email or wrong password
    And the blocked state is not disclosed

  # requirement_id: REQUIREMENT-007
  # scenario_id: SCENARIO-017
  Scenario: An authenticated learner signs out
    Given a learner has an authenticated session
    When the learner signs out
    Then that session ends
    And the learner returns to a signed-out experience

  # scenario_id: SCENARIO-018
  Scenario: A signed-out visitor requests sign-out
    Given no authenticated session exists
    When sign-out is requested
    Then the visitor remains signed out
    And no private account information is shown

  # requirement_id: REQUIREMENT-008
  # scenario_id: SCENARIO-019
  Scenario: An ended session cannot be reused
    Given a learner's session has ended
    When that session is used for an authenticated action
    Then the action is denied
    And sign-in is required

  # requirement_id: REQUIREMENT-009
  # scenario_id: SCENARIO-020
  Scenario: Blocking ends every existing session
    Given an administrator has blocked a learner with one or more existing sessions
    When any existing session is used for an ordinary authenticated action
    Then the action is denied
    And every existing session is ended
    And later unblocking does not resume any ended session
    And a new sign-in is required after unblocking
