require 'bundler/setup'
require 'wurfl_device'
require 'yaml'

namespace :wurfl do
  desc "initialize wurfl device cache"
  task :init do
    WurflDevice::Cache.storage.flushdb
    WurflDevice::Cache.initialize_cache! File.expand_path('../wurfl.xml', File.dirname(__FILE__))
  end

  desc "dump handset info"
  task :dump do
    raise WurflDevice::CacheError, 'cache is not initialized' unless WurflDevice::Cache.valid?
    raise WurflDevice::CacheError, 'please specify handset id' unless ENV['HANDSET']

    handset = WurflDevice::Cache.handsets[ENV['HANDSET']]
    if ENV['CAPA']
      $stdout.puts handset.capabilities.send(ENV['CAPA']).to_yaml
    else
      $stdout.puts handset.capabilities.to_yaml
    end
  end
end
