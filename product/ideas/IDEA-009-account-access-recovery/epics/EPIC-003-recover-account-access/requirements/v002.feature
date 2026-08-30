---
id: EPIC-003
kind: epic
version: 2
author: bootcamper_business_analyst
run_id: RUN-20260830T203654Z-69a65e
created_at: '2026-08-30T20:36:54Z'
previous_version: 1
reason: Resolve TL question by distinguishing the old password from its replacement
source_versions:
  IDEA-009: 3
  EPIC-003: 1
assumptions:
  - Email is the sole recovery identifier.
  - Recovery replaces the account password.
  - Recovery does not itself confirm an unconfirmed email.
  - A blocked account may complete recovery but remains blocked.
  - Successful recovery ends all existing sessions.
unresolved_questions: []
state: BA-ready
---
Feature: Recover account access

  # requirement_id: REQUIREMENT-010
  # scenario_id: SCENARIO-021
  Scenario: Recovery is requested for an eligible account
    Given a learner account exists for an email
    When recovery is requested for that email
    Then the requester sees a generic acknowledgement
    And no account existence or status is disclosed
    And the learner can receive current recovery proof

  # scenario_id: SCENARIO-022
  Scenario: Recovery is requested for an unknown email
    Given no account exists for an email
    When recovery is requested for that email
    Then the requester sees the same generic acknowledgement
    And no account information is disclosed

  # scenario_id: SCENARIO-023
  Scenario: An inactive learner requests recovery
    Given an inactive learner account exists for an email
    When recovery is requested for that email
    Then the requester sees the same generic acknowledgement
    And recovery may continue without confirming the account

  # scenario_id: SCENARIO-024
  Scenario: A blocked learner requests recovery
    Given a blocked learner account exists for an email
    When recovery is requested for that email
    Then the requester sees the same generic acknowledgement
    And recovery may continue without removing the block

  # requirement_id: REQUIREMENT-011
  # scenario_id: SCENARIO-025
  Scenario: A learner replaces a forgotten password
    Given a learner has valid current recovery proof
    When the learner submits an acceptable replacement password
    Then the password is replaced
    And the learner is told that recovery succeeded

  # scenario_id: SCENARIO-026
  Scenario: Recovery proof is invalid
    Given a learner presents invalid recovery proof
    When password replacement is attempted
    Then the password is unchanged
    And the learner is told to request recovery again

  # scenario_id: SCENARIO-027
  Scenario: Recovery proof has expired
    Given a learner presents expired recovery proof
    When password replacement is attempted
    Then the password is unchanged
    And the learner is told to request recovery again

  # scenario_id: SCENARIO-028
  Scenario: Recovery proof was already used
    Given a learner presents recovery proof that was already used
    When password replacement is attempted
    Then the password is unchanged
    And the learner is told that the proof cannot be used

  # scenario_id: SCENARIO-029
  Scenario: Recovery proof was superseded
    Given a learner presents recovery proof replaced by a newer recovery request
    When password replacement is attempted
    Then the password is unchanged
    And the learner is told to use the latest recovery proof or request recovery again

  # scenario_id: SCENARIO-030
  Scenario: A replacement password is unacceptable
    Given a learner has valid current recovery proof
    When the learner submits a password that does not meet the stated password rules
    Then the password is unchanged
    And the learner sees what must be corrected

  # requirement_id: REQUIREMENT-012
  # scenario_id: SCENARIO-031
  Scenario: Recovered credentials replace the forgotten credentials
    Given a learner successfully replaced the old password with a replacement password
    When the learner signs in with the replacement password
    Then sign-in succeeds if the account is confirmed and unblocked
    When the learner later submits the old password
    Then sign-in does not succeed

  # scenario_id: SCENARIO-032
  Scenario: Recovery does not activate an unconfirmed account
    Given an inactive learner successfully replaced the password
    When the learner attempts ordinary sign-in
    Then no authenticated session starts
    And email confirmation is still required

  # scenario_id: SCENARIO-033
  Scenario: Recovery does not unblock an administratively blocked account
    Given a blocked learner successfully replaced the password
    When the learner attempts ordinary sign-in
    Then no authenticated session starts
    And the account remains blocked

  # requirement_id: REQUIREMENT-013
  # scenario_id: SCENARIO-034
  Scenario: Successful recovery ends all existing sessions
    Given a learner has one or more authenticated sessions
    And the learner successfully replaces the password
    When any existing session is used for an authenticated action
    Then the action is denied
    And sign-in with the replacement password is required
