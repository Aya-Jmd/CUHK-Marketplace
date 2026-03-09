Feature: Signing Out from the Items Index Page
  As a logged-in CUHK user
  I want to sign out from the marketplace index page
  So that my account is safely logged out on shared devices

  Background:
    Given there is a college named "Shaw"
    And there is a user with email "user@link.cuhk.edu.hk", password "password123", and college "Shaw"
    And I am logged in as "user@link.cuhk.edu.hk"
    And I am on the marketplace page

  Scenario: User signs out from items index
    When I click "Sign out"
    Then I should be signed out
    And I should be redirected to the login page
