$:.unshift File.expand_path("../../../lib", __FILE__)

require 'zlib' 
require 'open-uri'
require 'wurfl_device'

Bench.run [0,1,2,3,4,5] do

  xml_url = "http://sourceforge.net/projects/wurfl/files/WURFL/2.3/wurfl-2.3.xml.gz/download"
  xml_file = '/tmp/wurfl.xml'

  File.open(xml_file, 'w') { |f| f.write(Zlib::GzipReader.new(open(xml_url)).read) } unless File.exists?(xml_file)
  WurflDevice::Cache.storage.flushdb
  WurflDevice::Cache.initialize_cache! xml_file

end
