Feature:

  In order for the wurfl device detection to work properly
  The device cache must be properly initialized

  Background:
    Given WurflDevice is used like:
      """
      require 'wurfl_device'
      """
    And a file named "wurfl.xml" should exist
    #When I download "http://sourceforge.net/projects/wurfl/files/WURFL/2.3/wurfl-2.3.xml.gz/download" saving it as "wurfl.xml"

  Scenario: initializing the wurfl device cache
    When I initialize the cache using xml file at "wurfl.xml"
    Then I should see the cache initialized
     And I should at least see a "generic" device

