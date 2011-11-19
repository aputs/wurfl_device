use Raindrops::Middleware, :stats => $stats, :path => '/_stats'

require ::File.expand_path('../lib/wurfl_device/web_service',  __FILE__)

run WurflDevice::WebService.new
