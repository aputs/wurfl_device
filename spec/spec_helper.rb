$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rspec/core'
require 'wurfl_device_matchers'

RSpec.configure do |config|
  config.mock_with :rspec
  config.color_enabled = true
end

require 'fakeredis/rspec' unless ENV['NOFAKEREDIS']
require 'wurfl_device'
