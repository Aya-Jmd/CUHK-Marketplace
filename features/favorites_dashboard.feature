Feature: Favorites dashboard curation
  As a CUHK student
  I want saved listings to stay easy to revisit
  So that my dashboard only surfaces favorites that are still live

  Background:
    Given a college named "Shaw"
    And a user exists with email "favorite_buyer@cuhk.edu.hk" in college "Shaw"
    And a user exists with email "favorite_seller@cuhk.edu.hk" in college "Shaw"

  Scenario: Buyer sees a favorited listing on the dashboard
    Given "favorite_seller@cuhk.edu.hk" listed "Desk Lamp" as global
    And I am logged in as "favorite_buyer@cuhk.edu.hk"
    When I favorite item "Desk Lamp"
    And I visit my dashboard
    Then my dashboard favorites should include "Desk Lamp"

  Scenario: Removed favorites are hidden from the dashboard
    Given "favorite_seller@cuhk.edu.hk" listed "Archived Chair" as global
    And item "Archived Chair" has status "removed"
    And "favorite_buyer@cuhk.edu.hk" favorited item "Archived Chair"
    And I am logged in as "favorite_buyer@cuhk.edu.hk"
    When I visit my dashboard
    Then my dashboard favorites should not include "Archived Chair"
