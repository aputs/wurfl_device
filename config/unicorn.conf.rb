require 'raindrops'
$stats ||= Raindrops::Middleware::Stats.new

app_env = ENV['RACK_ENV'] || 'development'
app_root = ::File.expand_path('../..', __FILE__)

timeout 60
worker_processes (app_env != 'development' ? 4 : 2)
listen "/tmp/wurfl_device/webservice.sock", :backlog => 64
pid "/tmp/wurfl_device/webservice.pid"
working_directory "#{app_root}"
stderr_path "/tmp/wurfl_device/webservice.log"
stdout_path "/tmp/wurfl_device/webservice.log"

preload_app false
