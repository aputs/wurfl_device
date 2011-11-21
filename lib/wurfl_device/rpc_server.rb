# encoding: utf-8
module WurflDevice
  class RpcServer
    def capabilities_from_id(device_id)
      capabilities = WurflDevice.capabilities_from_id(device_id)
      yield(capabilities)
    end

    def capabilities_from_user_agent(user_agent)
      capabilities = WurflDevice.capabilities_from_user_agent(user_agent)
      yield(capabilities)
    end

    def capability_from_user_agent(capability, user_agent)
      capabilities = WurflDevice.capability_from_user_agent(capability, user_agent)
      yield(capabilities)
    end
  end
end
