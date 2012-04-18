require 'wurfl_device'
require 'yaml'

module WurflDevice
  class WebService
    def call(env)
      handset = WurflDevice.handset_from_user_agent(env['HTTP_USER_AGENT'] || '-')
      out = handset.full_capabilities.to_yaml
      [200, {"Content-Type" => "application/json"}, [out]]
    end
  end
end