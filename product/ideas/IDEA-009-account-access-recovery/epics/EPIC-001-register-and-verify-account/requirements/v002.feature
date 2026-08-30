---
id: EPIC-001
kind: epic
version: 2
author: bootcamper_business_analyst
run_id: RUN-20260830T203654Z-69a65e
created_at: '2026-08-30T20:36:54Z'
previous_version: 1
reason: Resolve TL questions about duplicate registration privacy resend entry points and proof supersession
source_versions:
  IDEA-009: 3
  EPIC-001: 1
assumptions:
  - Email is the sole account identifier.
  - Registration requires email and password.
  - A newly created account remains inactive until its email is confirmed.
  - A blocked account may complete confirmation but remains blocked.
unresolved_questions: []
state: BA-ready
---
Feature: Register and verify a learner account

  # requirement_id: REQUIREMENT-001
  # scenario_id: SCENARIO-001
  Scenario: A visitor creates a learner account
    Given no learner account exists for the visitor's email
    When the visitor submits a valid email and password
    Then the visitor sees that the account was created
    And the account is inactive pending email confirmation
    And the visitor is told to check email and confirm ownership

  # scenario_id: SCENARIO-002
  Scenario: Registration information is invalid
    Given a visitor is registering
    When the visitor submits an invalid email or unacceptable password
    Then no account is created
    And the visitor sees which submitted information must be corrected

  # requirement_id: REQUIREMENT-002
  # scenario_id: SCENARIO-003
  Scenario: Registration does not disclose an existing account
    Given a learner account already exists for an email
    When a visitor submits that email for registration
    Then the visitor sees the same visible acknowledgement and wording as successful registration
    And the visitor is told to check email
    And no second account is created

  # requirement_id: REQUIREMENT-003
  # scenario_id: SCENARIO-004
  Scenario: A learner confirms email ownership
    Given an inactive learner has valid current confirmation proof
    When the learner confirms the email
    Then the account becomes confirmed
    And the learner is told that ordinary sign-in is available

  # scenario_id: SCENARIO-005
  Scenario: Confirmation proof is invalid
    Given a learner presents invalid confirmation proof
    When confirmation is attempted
    Then no account state changes
    And the learner is told to request another confirmation

  # scenario_id: SCENARIO-006
  Scenario: Confirmation proof has expired
    Given a learner presents expired confirmation proof
    When confirmation is attempted
    Then no account state changes
    And the learner is told to request another confirmation

  # scenario_id: SCENARIO-007
  Scenario: Confirmation proof was already used
    Given a learner presents confirmation proof that was already used
    When confirmation is attempted
    Then no account state changes
    And the learner sees that the proof cannot be used

  # scenario_id: SCENARIO-008
  Scenario: Confirmation proof was superseded
    Given a learner presents any confirmation proof issued before the newest proof
    When confirmation is attempted
    Then no account state changes
    And the learner is told to use the newest confirmation or request another

  # requirement_id: REQUIREMENT-004
  # scenario_id: SCENARIO-009
  Scenario: An inactive learner requests another confirmation
    Given an inactive learner account exists for an email
    When confirmation is requested through the public email form
    Then the requester sees a generic acknowledgement
    And the learner can use the newest confirmation proof
    And every earlier confirmation proof for the account is superseded

  # scenario_id: SCENARIO-010
  Scenario: Confirmation is requested for an unknown email
    Given no account exists for an email
    When confirmation is requested for that email
    Then the requester sees the same generic acknowledgement
    And no account information is disclosed

  # scenario_id: SCENARIO-011
  Scenario: Confirmation is requested for an already confirmed account
    Given a confirmed account exists for an email
    When confirmation is requested for that email
    Then the requester sees the same generic acknowledgement
    And no account status is disclosed

  # requirement_id: REQUIREMENT-005
  # scenario_id: SCENARIO-012
  Scenario: A blocked learner confirms email ownership without restoring access
    Given a blocked learner has valid current confirmation proof
    When the learner confirms the email
    Then email ownership becomes confirmed
    And the account remains blocked
    And ordinary sign-in remains unavailable
