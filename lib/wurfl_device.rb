# encoding: utf-8
require 'wurfl_device/version'
require 'msgpack'

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

    def capabilities_from_user_agent(user_agent)
      matcher = UserAgentMatcher.new
      matcher.match(user_agent)
      matcher.capabilities
    end
  end
end

require 'wurfl_device/railtie' if defined?(Rails)
