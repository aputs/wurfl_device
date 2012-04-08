require 'spec_helper'

module WurflDevice
  describe UserAgentMatcher do
    before(:each) do
      WurflDevice.configure do
        config.xml_url = "http://sourceforge.net/projects/wurfl/files/WURFL/2.3.1/wurfl-2.3.1.xml.gz/download"
        config.xml_file = "/tmp/wurfl.xml"
        config.redis_host = '127.0.0.1'
        config.redis_port = 6379
        config.redis_db = 2
        initialize_cache! unless cache_valid?
      end
    end

    it { should user_agent_matcher('SonyEricssonK700i/R2AG SEMC-Browser/4.0.3 Profile/MIDP-2.0 Configuration/CLDC-1.1').as('SonyEricsson') }
    it { should user_agent_matcher('Mozilla/5.0 (PlayBook; U; RIM Tablet OS 1.0.0; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/0.0.1 Safari/534.8+').as('SonyEricsson') }
    it { should user_agent_matcher('Mozilla/5.0 (BlackBerry; U; BlackBerry AAAA; en-US) AppleWebKit/534.11+ (KHTML, like Gecko) Version/X.X.X.X Mobile Safari/534.11+').as('SonyEricsson') }
    it { should user_agent_matcher('SAMSUNG-SGH-E200/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 UP.Browser/6.2.3.3.c.1.101 (GUI) MMP/2.0').as('SonyEricsson') }
  end
end