# encoding: utf-8

begin
  require 'bundler'
  Bundler::GemHelper.install_tasks
rescue LoadError
  $stderr.puts "Bundler not installed. You should install it with: gem install bundler"
end

$LOAD_PATH << File.expand_path('./lib', File.dirname(__FILE__))

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
rescue LoadError
  $stderr.puts "RSpec not available. Install it with: gem install rspec"
end

task :default => :spec

Dir.glob(File.join(File.dirname(__FILE__), 'lib', 'tasks', '*.rake')).each { |r| import r }
