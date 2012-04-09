$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rspec/core'
require 'wurfl_device_matchers'

require 'redis'
require 'wurfl_device'

RSpec.configure do |config|
  config.mock_with :rspec
  config.color_enabled = true

  config.before do
    WurflDevice::Cache.disconnect!
    Redis::Connection.drivers.clear
    Redis::Connection.drivers << Redis::Connection::Ruby
  end
end

