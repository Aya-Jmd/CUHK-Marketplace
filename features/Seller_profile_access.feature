Feature: Seeing a Seller's Profile from an Item Page
  As a CUHK marketplace user
  I want to access seller profile information
  So that I can verify identity and manage my own profile correctly

  Scenario: Seller is different from current user, profile page is read-only
    Given there is a college named "Shaw"
    And there is a college named "New Asia"
    And there is a seller with email "seller@link.cuhk.edu.hk" from "Shaw"
    And there is a buyer with email "buyer@link.cuhk.edu.hk" from "New Asia"
    And there is an item "Graphing Calculator" listed by "seller@link.cuhk.edu.hk"
    And I am logged in as "buyer@link.cuhk.edu.hk"
    When I open the item page for "Graphing Calculator"
    And I click on the seller name "seller@link.cuhk.edu.hk"
    Then I should be on the profile page of "seller@link.cuhk.edu.hk"
    And I should see the seller email "seller@link.cuhk.edu.hk"
    And I should see the seller college "Shaw"
    But I should not see "Edit Profile"

  Scenario: Seller is the current user, profile page is editable
    Given there is a college named "Shaw"
    And there is a seller with email "seller@link.cuhk.edu.hk" from "Shaw"
    And there is an item "Graphing Calculator" listed by "seller@link.cuhk.edu.hk"
    And I am logged in as "seller@link.cuhk.edu.hk"
    When I open the item page for "Graphing Calculator"
    And I click on the seller name "seller@link.cuhk.edu.hk"
    Then I should be on my profile page
    And I should see my displayed name
    And I should see my email "seller@link.cuhk.edu.hk"
    And I should see "Edit Profile"
