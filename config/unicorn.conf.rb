$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'wurfl_device'
require 'raindrops'

$stats ||= Raindrops::Middleware::Stats.new

FileUtils.mkdir_p(WurflDevice::Settings::BASE_DIR) unless File.directory?(WurflDevice::Settings::BASE_DIR)

app_env = ENV['RACK_ENV'] || 'production'
app_root = ::File.expand_path('../..', __FILE__)

app_timeout       = 60
app_workers       = WurflDevice::Settings::WEBSERVICE_WORKER
app_listen_socket = File.join(WurflDevice::Settings::BASE_DIR, WurflDevice::Settings::WEBSERVICE_SOCKET)
app_pid_file      = File.join(WurflDevice::Settings::BASE_DIR, WurflDevice::Settings::WEBSERVICE_PID)
app_log_file      = File.join(WurflDevice::Settings::BASE_DIR, WurflDevice::Settings::WEBSERVICE_LOG)

timeout app_timeout
working_directory app_root
worker_processes (app_env != 'development' ? app_workers : 1)
listen app_listen_socket, :backlog => 64
pid app_pid_file
stderr_path app_log_file
stdout_path app_log_file

preload_app false
