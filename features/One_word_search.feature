Feature: Searching an Item in the Search Bar
  As a CUHK student
  I want to search for an item by keyword
  So that I can quickly find relevant listings

  Background:
    Given there is an item "iPad Air"
    And there is an item "Wooden Desk"
    And there is an item "Linear Algebra Textbook"
    And I am on the marketplace page

  Scenario: Searching for an item using the search bar
    When I fill in the search bar with "desk"
    And I click "Search"
    Then I should see "Wooden Desk"
    But I should not see "iPad Air"
    And I should not see "Linear Algebra Textbook"
