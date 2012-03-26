$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rspec/core'
require 'wurfl_device_matchers'

RSpec.configure do |config|
  config.mock_with :rspec
  config.color_enabled = true
end

require 'fakeredis' unless ENV['NO_FAKE_REDIS']
require 'wurfl_device'
