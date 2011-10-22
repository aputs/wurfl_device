$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'wurfl_device'
require 'raindrops'

$stats ||= Raindrops::Middleware::Stats.new

FileUtils.mkdir_p(WurflDevice::Constants::WEBSERVICE_ROOT) unless File.directory?(WurflDevice::Constants::WEBSERVICE_ROOT)

app_env = ENV['RACK_ENV'] || 'production'
app_root = ::File.expand_path('../..', __FILE__)

timeout 60
working_directory app_root
worker_processes (app_env != 'development' ? WurflDevice::Constants::WEBSERVICE_WORKER : 1)
listen File.join(WurflDevice::Constants::WEBSERVICE_ROOT, WurflDevice::Constants::WEBSERVICE_SOCKET), :backlog => 64
pid File.join(WurflDevice::Constants::WEBSERVICE_ROOT, WurflDevice::Constants::WEBSERVICE_PID)
stderr_path File.join(WurflDevice::Constants::WEBSERVICE_ROOT, WurflDevice::Constants::WEBSERVICE_LOG)
stdout_path File.join(WurflDevice::Constants::WEBSERVICE_ROOT, WurflDevice::Constants::WEBSERVICE_LOG)

preload_app false
