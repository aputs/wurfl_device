@ok
Feature:

  In order for the wurfl device detection to work properly
  The device cache must be properly initialized

  Background: initializing the wurfl device cache
    Given WurflDevice cached is initialized

  Scenario: generic handsets
    When I successfully run `rake wurfl:dump HANDSET='generic' CAPA='id'`
    Then the output should contain "generic"

    When I successfully run `rake wurfl:dump HANDSET='generic_xhtml' CAPA='id'`
    Then the output should contain "generic_xhtml"

    When I successfully run `rake wurfl:dump HANDSET='generic_web_browser' CAPA='id'`
    Then the output should contain "generic_web_browser"
