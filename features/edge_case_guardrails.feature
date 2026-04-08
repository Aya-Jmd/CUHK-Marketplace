Feature: Marketplace edge-case guardrails
  As a platform team
  I want invalid actions blocked cleanly
  So that users cannot break transaction or chat flows

  Background:
    Given a college named "Shaw"
    And a user exists with email "seller_edge@cuhk.edu.hk" in college "Shaw"
    And a user exists with email "buyer_edge@cuhk.edu.hk" in college "Shaw"
    And "seller_edge@cuhk.edu.hk" listed "Edge Keyboard" as global

  Scenario: Seller cannot complete with wrong PIN
    Given offer exists on "Edge Keyboard" from "buyer_edge@cuhk.edu.hk" with status "accepted" and code "1234"
    And I am logged in as "seller_edge@cuhk.edu.hk"
    When I complete that offer using code "9999"
    Then item "Edge Keyboard" should have status "available"
    And that offer should have status "accepted"

  Scenario: Buyer cannot start chat with blank message
    Given I am logged in as "buyer_edge@cuhk.edu.hk"
    When I open item "Edge Keyboard"
    And I send initial chat message "   "
    Then conversation should not exist for item "Edge Keyboard" between "buyer_edge@cuhk.edu.hk" and "seller_edge@cuhk.edu.hk"
