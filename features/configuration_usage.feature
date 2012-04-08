@ok
Feature:

  In normal usage of WurflDevice
  a configuration can be specified

  Scenario: cache with user configuration
    Given a file named "cache_init_with_config.rb" with:
      """
      require 'wurfl_device'

      WurflDevice.configure do
        config.xml_url = "http://sourceforge.net/projects/wurfl/files/WURFL/2.3.1/wurfl-2.3.1.xml.gz/download"
        config.xml_file = "/tmp/wurfl.xml"
        config.redis_host = '127.0.0.1'
        config.redis_port = 6379
        config.redis_db = 2
        initialize_cache!
      end

      puts "cache initialialized." if WurflDevice.cache_valid?
      """

    When I successfully run `ruby cache_init_with_config.rb`
    Then the output should contain "cache initialialized."
