Feature: Chat and notifications
  As a buyer and seller
  I want communication and alerts in-app
  So that I do not rely on external channels

  Background:
    Given a college named "Shaw"
    And a user exists with email "seller@cuhk.edu.hk" in college "Shaw"
    And a user exists with email "buyer@cuhk.edu.hk" in college "Shaw"
    And "seller@cuhk.edu.hk" listed "Rice Cooker" as global

  Scenario: Buyer starts conversation from listing page
    Given I am logged in as "buyer@cuhk.edu.hk"
    When I open item "Rice Cooker"
    And I send initial chat message "Can we meet near Shaw College?"
    Then conversation for item "Rice Cooker" should include message "Can we meet near Shaw College?"

  Scenario: Seller clears unread notifications
    Given an offer exists on "Rice Cooker" from "buyer@cuhk.edu.hk"
    And I am logged in as "seller@cuhk.edu.hk"
    When I mark all my notifications as read
    Then I should have no unread notifications
