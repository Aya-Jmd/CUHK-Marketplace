Feature: Offer transaction lifecycle
  As a seller
  I want to manage offer states safely
  So that item lifecycle is consistent and double-booking is prevented

  Background:
    Given a college named "Shaw"
    And a user exists with email "seller@cuhk.edu.hk" in college "Shaw"
    And a user exists with email "buyer@cuhk.edu.hk" in college "Shaw"
    And "seller@cuhk.edu.hk" listed "Gaming Mouse" as global

  Scenario: Buyer sends an offer from item page
    Given I am logged in as "buyer@cuhk.edu.hk"
    When I open item "Gaming Mouse"
    And I submit offer price "150"
    Then the latest offer for "Gaming Mouse" should belong to "buyer@cuhk.edu.hk"
    And the latest offer status should be "pending"

  Scenario: Seller completes transaction with meetup code
    Given offer exists on "Gaming Mouse" from "buyer@cuhk.edu.hk" with status "accepted" and code "1234"
    And I am logged in as "seller@cuhk.edu.hk"
    When I complete that offer using code "1234"
    Then item "Gaming Mouse" should have status "sold"
    And that offer should have status "completed"
