$:.unshift File.expand_path("../../../lib", __FILE__)

require 'zlib' 
require 'open-uri'
require 'wurfl_device'

Bench.run [0] {

  WurflDevice.configure do
    config.xml_url = "http://sourceforge.net/projects/wurfl/files/WURFL/2.3.1/wurfl-2.3.1.xml.gz/download"
    config.xml_file = "/tmp/wurfl.xml"
    config.redis_host = '127.0.0.1'
    config.redis_port = 6379
    config.redis_db = 2
    initialize_cache!
  end

  WurflDevice.initialize_cache!

}
