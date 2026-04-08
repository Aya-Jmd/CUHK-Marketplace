Feature: Marketplace browsing and intelligent search
  As a CUHK student
  I want to discover relevant listings quickly
  So that I can find items from my college and across CUHK

  Background:
    Given a college named "Shaw"
    And a college named "New Asia"
    And a user exists with email "buyer@cuhk.edu.hk" in college "Shaw"
    And a user exists with email "shaw_seller@cuhk.edu.hk" in college "Shaw"
    And a user exists with email "na_seller@cuhk.edu.hk" in college "New Asia"

  Scenario: Buyer sees own college and global items
    Given "shaw_seller@cuhk.edu.hk" listed "Local Chair" as local
    And "na_seller@cuhk.edu.hk" listed "Global Calculator" as global
    And "na_seller@cuhk.edu.hk" listed "Hidden Kettle" as local
    And I am logged in as "buyer@cuhk.edu.hk"
    When I visit the homepage
    Then I should see "Local Chair"
    And I should see "Global Calculator"
    And I should not see "Hidden Kettle"

  Scenario: Buyer searches by keyword
    Given category "Books" exists
    And category "Electronics" exists
    And "shaw_seller@cuhk.edu.hk" listed "Calculus Textbook" in category "Books"
    And "shaw_seller@cuhk.edu.hk" listed "Phone Adapter" in category "Electronics"
    And I am logged in as "buyer@cuhk.edu.hk"
    When I visit search page with query "calc"
    Then I should see "Calculus Textbook"
    And I should not see "Phone Adapter"
