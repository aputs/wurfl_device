require 'bundler/setup'
require 'wurfl_device'
require 'open-uri'
require 'zlib'
require 'yaml'

namespace :wurfl do
  desc "download wurfl device list from sourceforge!"
  task :download do
    wurfl_url = "http://sourceforge.net/projects/wurfl/files/WURFL/2.3.1/wurfl-2.3.1.xml.gz/download"
    File.open(ENV['WURFL_XML'] || '/tmp/wurfl.xml', 'w') { |f| f.write(Zlib::GzipReader.new(open(wurfl_url)).read) }
  end

  desc "initialize wurfl device cache"
  task :init do
    WurflDevice.configure do
      config.xml_file = ENV['WURFL_XML'] || File.expand_path('../wurfl.xml', File.dirname(__FILE__))
      config.redis_db = 2
      initialize_cache! 
    end
  end

  desc "dump handset info"
  task :dump do
    WurflDevice.configure do
      config.redis_db = 2
    end

    raise WurflDevice::CacheError, 'cache is not initialized' unless WurflDevice.cache_valid?
    raise WurflDevice::CacheError, 'please specify handset id' unless ENV['HANDSET']

    handset = WurflDevice.handsets[ENV['HANDSET']]
    if ENV['CAPA']
      $stdout.puts handset.capabilities.send(ENV['CAPA']).to_yaml
    else
      $stdout.puts handset.full_capabilities.to_yaml
    end
  end
end
