Feature: Signing Up
  As a new CUHK user
  I want to create an account
  So that I can access the marketplace

  Scenario: Successful sign up
    Given there is a college named "Shaw"
    When I visit the sign up page
    And I fill in "Email" with "newuser@link.cuhk.edu.hk"
    And I fill in "Password" with "password123"
    And I fill in "Password confirmation" with "password123"
    And I select "Shaw" from "Select your CUHK College"
    And I click "Sign up"
    Then I should see a confirmation that my account was created
    And I should be signed in
