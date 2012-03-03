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

  if RUBY_VERSION >= '1.9'
    RSpec::Core::RakeTask.new(:cov) do |t|
      ENV['ENABLE_SIMPLECOV'] = '1'
      t.ruby_opts = '-w'
      t.rcov_opts = %q[-Ilib --exclude "spec/*,gems/*"]
    end
  end
rescue LoadError
  $stderr.puts "RSpec not available. Install it with: gem install rspec-core rspec-expectations rr faker"
end

task :default => :spec

Dir.glob(File.join(File.dirname(__FILE__), 'lib', 'tasks', '*.rake')).each { |r| import r }