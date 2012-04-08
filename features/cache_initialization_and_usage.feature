@ok
Feature:

  In order for the wurfl device detection to work properly
  The device cache must be properly initialized

  Scenario Outline:
    Given a file named "cache_init.rb" with:
      """
      require 'wurfl_device'

      WurflDevice.configure do
        config.xml_url = "http://sourceforge.net/projects/wurfl/files/WURFL/2.3.1/wurfl-2.3.1.xml.gz/download"
        config.xml_file = "/tmp/wurfl.xml"
        config.redis_host = '127.0.0.1'
        config.redis_port = 6379
        config.redis_db = 2
        initialize_cache! unless cache_valid?
      end

      puts WurflDevice.handsets["<device_id>"].id if WurflDevice.handsets["<device_id>"]
      """

    When I successfully run `ruby cache_init.rb`
    Then the output should contain "<device_id>"

    Examples:
    | device_id           |
    | generic             |
    | generic_xhtml       |
    | generic_web_browser |
