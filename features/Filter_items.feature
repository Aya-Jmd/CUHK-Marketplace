Feature: Filtering Items by Category and Price
  As a CUHK student
  I want to filter listings by category and price range
  So that I can browse items that fit my needs and budget

  Background:
    Given there is an item "iPad Air" priced "2800" in category "Electronics"
    And there is an item "Linear Algebra Textbook" priced "180" in category "Books"
    And there is an item "Wooden Desk" priced "1200" in category "Furniture"
    And I am on the marketplace page

  Scenario: Filtering items by category
    When I choose category "Books"
    And I click "Apply filters"
    Then I should see "Linear Algebra Textbook"
    But I should not see "iPad Air"
    And I should not see "Wooden Desk"

  Scenario: Filtering items by price range
    When I set the minimum price to "1000"
    And I set the maximum price to "3000"
    And I click "Apply"
    Then I should see "iPad Air"
    And I should see "Wooden Desk"
    But I should not see "Linear Algebra Textbook"
