Feature:

  In order for the wurfl device detection to work properly
  The device cache must be properly initialized

  Background:
    Given WurflDevice is used like:
      """
      require 'wurfl_device'
      """
  Scenario: downloading the wurfl files
    Given gzipped xml file at "http://sourceforge.net/projects/wurfl/files/WURFL/2.3/wurfl-2.3.xml.gz/download"
    When I download the xml file saving it as "/tmp/wurfl.xml"
    Then I should see the xml file

  Scenario: initializing the wurfl device cache
    When I initialize the cache using xml file at "/tmp/wurfl.xml"
    Then I should see the cache initialized
     And I should at least see a "generic" device

