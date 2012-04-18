require 'sinatra'

module WurflDevice
  class WebService < Sinatra::Application
    def handset_from_user_agent
      cache_control :public, :must_revalidate, :max_age => 60
      [200, {"Content-Type" => "application/json"}, [WurflDevice.handset_from_user_agent(request.user_agent).full_capabilities.to_json]]
    end
  end
end