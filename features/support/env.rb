require 'bundler'
Bundler.setup

require 'rspec/expectations'
require 'fileutils'
require 'aruba/cucumber'

Before do
  @aruba_timeout_seconds = 120
  this_dir = File.dirname(__FILE__)
  in_current_dir do
    FileUtils.rm_rf 'project'
    FileUtils.cp_r File.join(this_dir, '../../spec/faked_project/'), 'project'
  end
  step %Q{I cd to "project"}
end
