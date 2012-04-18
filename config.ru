#\ -w -p 8800 -s puma
$LOAD_PATH.unshift(File.expand_path('lib', File.dirname(__FILE__)))

require 'wurfl_device/web_service'

#use Rack::ContentLength
#use Rack::Lint

# preload wurfl device lookup tables
WurflDevice::Cache::HandsetsList.handsets_and_user_agents
WurflDevice::Cache::CapabilityList.capabilities
WurflDevice::Cache::UserAgentsMatchers.user_agent_matchers.map { |m| WurflDevice::Cache::UserAgentsMatchers.user_agents_for_brand(m) }

map "/" do
  run WurflDevice::WebService.new
end
