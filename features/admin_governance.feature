Feature: Admin governance and setup hardening
  As a marketplace operator
  I want secure admin onboarding and invitation rules
  So that only authorized users manage the platform

  Background:
    Given a college named "Shaw"
    And a college named "S.H. Ho"

  Scenario: College admin is redirected to setup before dashboard
    Given an admin user "college_admin@cuhk.edu.hk" exists with role "college_admin" in college "Shaw" and setup "false"
    And I am logged in as "college_admin@cuhk.edu.hk"
    When I visit the admin dashboard
    Then I should be on the admin setup page

  Scenario: Super admin invites a college admin
    Given an admin user "super_admin@cuhk.edu.hk" exists with role "admin" in college "Shaw" and setup "true"
    And I am logged in as "super_admin@cuhk.edu.hk"
    When I visit the admin dashboard
    And I invite admin user "fresh_college_admin@cuhk.edu.hk" with role "college_admin" and college "S.H. Ho"
    Then invited user "fresh_college_admin@cuhk.edu.hk" should exist with role "college_admin"
