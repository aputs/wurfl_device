#\ -w -p 8765 -s puma
$LOAD_PATH.unshift(File.expand_path('lib', File.dirname(__FILE__)))

require 'yaml'
require 'wurfl_device'

# TODO since, need to mutex wurfl_device internal cache
use Rack::Reloader, 0
use Rack::ContentLength
use Rack::Lint

app_handset_from_user_agent = lambda do |env|
  handset = WurflDevice.handset_from_user_agent(env['HTTP_USER_AGENT'] || '-')
  out = handset.full_capabilities.to_yaml
  return [200, {"Content-Type" => "application/json"}, [out]]
end

map "/" do
  run app_handset_from_user_agent
end
