Feature: Admin user moderation
  As a college admin
  I want moderation controls limited to my scope
  So that student accounts can be managed without overreach

  Background:
    Given a college named "Shaw"
    And a college named "New Asia"

  Scenario: College admin bans a student from the same college
    Given an admin user "moderator@cuhk.edu.hk" exists with role "college_admin" in college "Shaw" and setup "true"
    And a user exists with email "student_to_ban@cuhk.edu.hk" in college "Shaw"
    And I am logged in as "moderator@cuhk.edu.hk"
    When I ban user "student_to_ban@cuhk.edu.hk"
    Then user "student_to_ban@cuhk.edu.hk" should be banned

  Scenario: College admin cannot ban a student from another college
    Given an admin user "moderator_cross_scope@cuhk.edu.hk" exists with role "college_admin" in college "Shaw" and setup "true"
    And a user exists with email "student_outside_scope@cuhk.edu.hk" in college "New Asia"
    And I am logged in as "moderator_cross_scope@cuhk.edu.hk"
    When I ban user "student_outside_scope@cuhk.edu.hk"
    Then user "student_outside_scope@cuhk.edu.hk" should not be banned
