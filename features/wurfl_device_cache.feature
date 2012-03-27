Feature:

  In order for the wurfl device detection to work properly
  The device cache must be properly initialized

  Background:
    Given WurflDevice is used like:
      """
      require 'wurfl_device'
      """

  Scenario: downloading the wurfl files
    Given gzipped files is at:
    | filename  | url                                                                             |
    | wurfl.xml | http://sourceforge.net/projects/wurfl/files/WURFL/2.3/wurfl-2.3.xml.gz/download |

    When I download the files saving them at "/tmp"
    Then I should see the xml files

  Scenario: initialize the wurfl device cache
    Given wurfl xml file at:
    | filename |
    | /tmp/wurfl.xml |

    When I inititialize cache
    Then I should see the cache initialized
