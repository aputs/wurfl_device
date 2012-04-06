# encoding: utf-8
require 'wurfl_device/version'

module WurflDevice
  autoload :Cache,              'wurfl_device/cache'
  autoload :Capability,         'wurfl_device/capability'
  autoload :CapabilityMapping,  'wurfl_device/capability_mapping'
  autoload :Handset,            'wurfl_device/handset'
  autoload :UserAgent,          'wurfl_device/user_agent'

  GENERIC                       = 'generic'
  GENERIC_XHTML                 = 'generic_xhtml'
  GENERIC_WEB_BROWSER           = 'generic_web_browser'

  WORST_MATCH                   = 7

  class WurflDeviceError < StandardError
    def self.status_code(code = nil); define_method(:status_code) { code }; end
  end
  class XMLFileError      < WurflDeviceError; status_code(10); end
  class CacheError        < WurflDeviceError; status_code(11); end
  class LockTimeout       < WurflDeviceError; status_code(12); end
  class CapabilityError   < WurflDeviceError; status_code(13); end
  class UserAgentError    < WurflDeviceError; status_code(14); end

  class << self
    def handset(id)
      Cache.handsets[id] || Handset.new(id)
    end
  end
end

require 'wurfl_device/railtie' if defined?(Rails)
