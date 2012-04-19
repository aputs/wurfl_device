require 'sinatra/base'

module WurflDevice
  class WebService < Sinatra::Base

    def handset_from_user_agent
      [200, {"Content-Type" => "application/json"}, [WurflDevice.handset_from_user_agent(request.user_agent).full_capabilities.to_json]]
    end

    get '/' do
      handset_from_user_agent
    end

    error 404 do
      @app.call(env)
    end
  end
end