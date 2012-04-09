require 'wurfl_device'

When /^I successfully initialize the cache$/ do
  WurflDevice.configure do
    config.xml_url = "http://sourceforge.net/projects/wurfl/files/WURFL/2.3.1/wurfl-2.3.1.xml.gz/download"
    config.xml_file = "/tmp/wurfl.xml"
    config.redis_host = '127.0.0.1'
    config.redis_port = 6379
    config.redis_db = 2
  end

  WurflDevice::Cache.storage.flushdb if WurflDevice.cache_valid? && WurflDevice::Cache.handsets.count < 50
  WurflDevice::initialize_cache! unless WurflDevice.cache_valid?
end

Then /^matching "([^"]*)" should be "([^"]*)"$/ do |arg1, arg2|
  WurflDevice::UserAgentMatcher.match(arg1).id.should == arg2
end