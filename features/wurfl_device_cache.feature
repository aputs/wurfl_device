@wip
Feature:

  In order for the wurfl device detection to work properly
  The device cache must be properly initialized

  Background: initializing the wurfl device cache
    Then I should see the cache initialized

  Scenario: generic handsets
    Then I should see a "generic" handset
     And I should see a "generic_xhtml" handset
     And I should see a "generic_web_browser" handset
