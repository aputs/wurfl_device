if RUBY_VERSION >= '1.9'
  if ENV['ENABLE_SIMPLECOV']
    require 'simplecov'
    SimpleCov.start
  end
else
  require 'rubygems'
end

require 'rspec/core'

$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

RSpec.configure do |config|
  config.mock_with :rr
  config.color_enabled = true
end

use_fake_redis = ENV['NO_FAKE_REDIS'].nil? ? true : false

require 'fakeredis' if use_fake_redis
require 'wurfl_device'

xml_file ||= WurflDevice::Settings.default_wurfl_xml_file
WurflDevice::Cache::initialize_cache(xml_file) unless WurflDevice::Cache.initialized?
