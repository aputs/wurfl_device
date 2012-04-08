require 'bundler/setup'
require 'wurfl_device'
require 'open-uri'
require 'zlib'
require 'yaml'

namespace :wurfl do
  @xml_url = "http://sourceforge.net/projects/wurfl/files/WURFL/2.3.1/wurfl-2.3.1.xml.gz/download"

  desc "download wurfl device list from sourceforge!"
  task :download do
    File.open(ENV['WURFL_XML'] || '/tmp/wurfl.xml', 'w') { |f| f.write(Zlib::GzipReader.new(open(@xml_url)).read) }
  end

  desc "initialize wurfl device cache"
  task :init do
    WurflDevice.configure do
      config.xml_url = ENV['WURFL_XML'] || @xml_url
      config.xml_file = '/tmp/wurfl.xml'
      initialize_cache!
    end
  end

  desc "dump handset info"
  task :dump do
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
