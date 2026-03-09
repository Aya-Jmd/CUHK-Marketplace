Feature: Viewing an Item Location on the CUHK Campus Map
  As a CUHK marketplace user
  I want to view where an item is located on campus
  So that I can decide whether pickup is convenient

  Background:
    Given there is a college named "Shaw"
    And there is a seller with email "seller@link.cuhk.edu.hk" from "Shaw"
    And there is an item "Mini Fridge" listed by "seller@link.cuhk.edu.hk" at map location "Shaw College Hostel 2"
    And I am logged in as "buyer@link.cuhk.edu.hk"

  Scenario: Viewing the item's location on the campus map
    When I open the item page for "Mini Fridge"
    And I click "View on CUHK Map"
    Then I should see a campus map
    And I should see a marker for "Mini Fridge"
    And I should see the location label "Shaw College Hostel 2"

  Scenario: Viewing distance to item when user location is enabled
    When I open the item page for "Mini Fridge"
    And I click "View on CUHK Map"
    And I enable my location
    Then I should see my current location on the map
    And I should see the distance from me to "Mini Fridge"
