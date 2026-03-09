Feature: Logging In for the First Time with Remember Me Behavior
  As a registered CUHK user
  I want login sessions to behave correctly based on my Remember me choice
  So that convenience and security both work as expected

  Background:
    Given there is a college named "Shaw"
    And there is a user with email "user@link.cuhk.edu.hk", password "password123", and college "Shaw"

  Scenario: Login without Remember me requires credentials next time
    When I visit the login page
    And I fill in "Email" with "user@link.cuhk.edu.hk"
    And I fill in "Password" with "password123"
    And I leave "Remember me" unchecked
    And I click "Log in"
    Then I should be signed in
    When I sign out
    And I return to the login page
    Then the "Email" field should be empty
    And the "Password" field should be empty

  Scenario: Login with Remember me keeps credentials for next login
    When I visit the login page
    And I fill in "Email" with "user@link.cuhk.edu.hk"
    And I fill in "Password" with "password123"
    And I check "Remember me"
    And I click "Log in"
    Then I should be signed in
    When I sign out
    And I return to the login page
    Then the "Email" field should be pre-filled with "user@link.cuhk.edu.hk"
