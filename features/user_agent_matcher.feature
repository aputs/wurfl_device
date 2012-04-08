@wip
Feature:

  I must be able to match user agent

  Scenario Outline:
    Given a file named "user_agent_matcher.rb" with:
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

      handset_id = WurflDevice.handset_from_user_agent("<user_agent>")
      puts handset_id
      """

    When I successfully run `ruby user_agent_matcher.rb`
    Then the output should contain "<handset_id>"

    Examples:
    | handset_id                     | user_agent                                                                                                                        |
    | rim_playbook_ver1              | Mozilla/5.0 (PlayBook; U; RIM Tablet OS 1.0.0; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/0.0.1 Safari/534.8+          |
    | blackberry9100_ver1_sub500604  | Mozilla/5.0 (BlackBerry; U; BlackBerry AAAA; en-US) AppleWebKit/534.11+ (KHTML, like Gecko) Version/X.X.X.X Mobile Safari/534.11+ |
    | sonyericsson_k700i_ver1subr2ay | SonyEricssonK700i/R2AG SEMC-Browser/4.0.3 Profile/MIDP-2.0 Configuration/CLDC-1.1                                                 |
    | samsung_sgh_e200_ver1          | SAMSUNG-SGH-E200/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 UP.Browser/6.2.3.3.c.1.101 (GUI) MMP/2.0                             |
