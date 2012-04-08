require 'bundler'
Bundler.setup

require 'rspec/expectations'
require 'fileutils'
require 'aruba/cucumber'
require 'wurfl_device'

# empty up test cache first
WurflDevice.configure do
  config.redis_db = 2
end

WurflDevice::Cache.storage.flushdb

Before do
  @aruba_timeout_seconds = 120
  this_dir = File.dirname(__FILE__)
  in_current_dir do
    FileUtils.rm_rf 'project'
    FileUtils.cp_r File.join(this_dir, '../../spec/faked_project/'), 'project'
  end
  step %Q{I cd to "project"}
end
