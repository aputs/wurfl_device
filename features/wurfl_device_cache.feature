@ok
Feature:

  In order for the wurfl device detection to work properly
  The device cache must be properly initialized

  Background:
    Given WurflDevice is used like:
      """
      require 'wurfl_device'
      """
    And a file named "wurfl.xml" should exist

  Scenario: initializing the wurfl device cache
    When I initialize the cache using xml file "wurfl.xml"
    Then I should see the cache initialized
     And I should at least see a "generic" handset
     And I should at least see a "generic_xhtml" handset
     And I should at least see a "generic_web_browser" handset
