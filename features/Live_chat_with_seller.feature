Feature: Starting a Live Chat with a Seller
  As a CUHK student buyer
  I want to start a live chat from an item's page
  So that I can ask the seller questions before buying

  Background:
    Given there is a college named "Shaw"
    And there is a college named "New Asia"
    And there is a seller with email "seller@link.cuhk.edu.hk" from "Shaw"
    And there is a buyer with email "buyer@link.cuhk.edu.hk" from "New Asia"
    And there is an item "Graphing Calculator" listed by "seller@link.cuhk.edu.hk"
    And I am logged in as "buyer@link.cuhk.edu.hk"

  Scenario: Starting a live chat with the seller from an item page
    When I open the item page for "Graphing Calculator"
    And I click "Message Seller"
    Then a live chat with "seller@link.cuhk.edu.hk" should start
    And the chat should be linked to the item "Graphing Calculator"
    And I should see "seller@link.cuhk.edu.hk" in the chat header
