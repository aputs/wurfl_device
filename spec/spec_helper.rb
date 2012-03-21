$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rspec/core'
require 'rspec_encoding_matchers'

RSpec.configure do |config|
  config.mock_with :rspec
  config.color_enabled = true
  config.include RSpecEncodingMatchers
end

require 'fakeredis' unless ENV['NO_FAKE_REDIS']
require 'wurfl_device'
