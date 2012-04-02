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

begin
  require "cucumber/rake/task"

  Cucumber::Rake::Task.new(:features, 'Run features that should pass') do |task|
    task.cucumber_opts = ["features"]
    task.profile = 'default'
  end

  namespace :features do
    Cucumber::Rake::Task.new(:wip, 'Run features that is work in progress') do |task|
      task.cucumber_opts = ["features"]
      task.profile = 'wip'
    end
  end
rescue LoadError
  $stderr.puts "Cucumber not available. Install it with: gem install cucumber"
end

task :default => [:spec, :features]
