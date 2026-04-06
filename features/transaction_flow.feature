Feature: Secure Item Transaction and Handshake
  As a buyer and seller
  In order to safely exchange items on campus
  We want to use a secure PIN system to confirm the meetup

  Scenario: Seller completes a transaction with a valid PIN
    Given a user "seller@example.com" has listed an item "CR7 Boots"
    And a user "buyer@example.com" has an "accepted" offer on "CR7 Boots" with PIN "5830"
    And I am logged in as "seller@example.com"
    When I go to my dashboard
    And I fill in "meetup_code" with "5830"
    And I click "Complete Sale"
    Then I should see a success message "Transaction Complete! Item officially sold."
    And the item "CR7 Boots" should have the status "sold"

  Scenario: Seller enters an invalid PIN
    Given a user "seller@example.com" has listed an item "CR7 Boots"
    And a user "buyer@example.com" has an "accepted" offer on "CR7 Boots" with PIN "5830"
    And I am logged in as "seller@example.com"
    When I go to my dashboard
    And I fill in "meetup_code" with "1111"
    And I click "Complete Sale"
    Then I should see an error message "Incorrect PIN. Please try again."
    And the item "CR7 Boots" should still have the status "pending_dropoff"