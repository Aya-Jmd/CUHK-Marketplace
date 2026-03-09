Feature: Price Analytics Dashboard by Category
  As a CUHK marketplace user
  I want to see historical price trends by category
  So that I can judge whether current listing prices are fair

  Background:
    Given there are historical prices for category "Electronics"
    And there are historical prices for category "Books"
    And I am logged in as "buyer@link.cuhk.edu.hk"

  Scenario: Viewing historical price trends for a selected category
    When I visit the price analytics dashboard
    And I select category "Electronics"
    Then I should see a historical price trend chart for "Electronics"
    And I should see summary metrics for "Electronics"

  Scenario: Checking market fairness for a category
    Given there is an item "iPad Air" in category "Electronics" priced "2800"
    When I visit the price analytics dashboard
    And I select category "Electronics"
    And I choose item "iPad Air"
    Then I should see the item's price compared with historical category prices
    And I should see a fairness indicator for the item's price
