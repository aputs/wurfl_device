require 'json'

module WurflDevice
  class WebService
    def call(env)
      handset = WurflDevice.handset_from_user_agent(env['HTTP_USER_AGENT'] || '-')
      [200, {"Content-Type" => "application/json"}, [handset.full_capabilities.to_json]]
    end
  end
end