# encoding: utf-8
require 'wurfl_device/version'

class Object
  def to_actual_value
    return self unless self.kind_of?(String)
    return false if self =~ /^false/i
    return true if self =~ /^true/i
    return self.to_i if (self == self.to_i.to_s)
    return self.to_f if (self == self.to_f.to_s)
    self
  end
end

module WurflDevice
  autoload :UI,                 'wurfl_device/ui'
  autoload :CLI,                'wurfl_device/cli'
  autoload :Capability,         'wurfl_device/capability'
  autoload :Cache,              'wurfl_device/cache'
  autoload :Handset,            'wurfl_device/handset'
  autoload :Settings,           'wurfl_device/settings'
  autoload :UserAgent,          'wurfl_device/user_agent'
  autoload :UserAgentMatcher,   'wurfl_device/user_agent_matcher'
  autoload :XmlLoader,          'wurfl_device/xml_loader'
  autoload :RpcServer,          'wurfl_device/rpc_server'

  class WurflDeviceError < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end

  class CacheError    < WurflDeviceError; status_code(10); end
  class XMLFileError  < WurflDeviceError; status_code(11); end

  class << self
    attr_writer :ui

    def ui
      @ui ||= UI.new
    end

    def capabilities_from_id(device_id)
      capabilities = Cache.build_capabilities(device_id)
      capabilities
    end

    def capability_from_user_agent(capability, user_agent)
      capability_key = capability
      if Settings::CAPABILITY_GROUPS.include?(capability)
        group_keys = Array.new
        Settings::CAPABILITY_TO_GROUP.select { |k, v| v == capability }.each_pair { |k, v| group_keys << "#{v}:#{k}" }
        group_vals = Cache.storage.hmget(Cache::UserAgents.build_cache_id(user_agent), *group_keys)
        return Cache.parse_actual_capabilities(Hash[*group_keys.zip(group_vals).flatten])[capability] if (group_vals.select { |v| v.nil? }.empty?)
      elsif Settings::CAPABILITY_TO_GROUP.key?(capability)
        capability_key = "#{Settings::CAPABILITY_TO_GROUP[capability]}:#{capability}"
      end
      actual_capability = WurflDevice::Cache::UserAgents.get(user_agent, capability_key)
      return actual_capability.to_actual_value unless actual_capability.nil?
      return nil
    end

    def capabilities_from_user_agent(user_agent)
      matcher = UserAgentMatcher.new
      matcher.match(user_agent)
      matcher.capabilities
    end
  end
end
