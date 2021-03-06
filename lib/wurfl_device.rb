# encoding: utf-8
require 'wurfl_device/version'
require 'open-uri'
require 'zlib'

module WurflDevice
  autoload :Cache,              'wurfl_device/cache'
  autoload :Config,             'wurfl_device/config'
  autoload :Capability,         'wurfl_device/capability'
  autoload :CapabilityMapping,  'wurfl_device/capability_mapping'
  autoload :Handset,            'wurfl_device/handset'
  autoload :UserAgent,          'wurfl_device/user_agent'
  autoload :UserAgentMatcher,   'wurfl_device/user_agent_matcher'

  GENERIC                       = 'generic'
  GENERIC_XHTML                 = 'generic_xhtml'
  GENERIC_WEB_BROWSER           = 'generic_web_browser'

  class WurflDeviceError  < StandardError; def self.status_code(code = nil); define_method(:status_code) { code }; end; end
  class XMLFileError      < WurflDeviceError; status_code(10); end
  class CacheError        < WurflDeviceError; status_code(11); end
  class LockTimeout       < WurflDeviceError; status_code(12); end
  class CapabilityError   < WurflDeviceError; status_code(13); end
  class UserAgentError    < WurflDeviceError; status_code(14); end

  class << self
    def config
      @@config ||= Config.new
    end

    def configure(&block)
      self.instance_eval(&block)
    end

    def initialize_cache!
      unless File.exists?(config.xml_file)
        File.open(config.xml_file, 'w') { |f| f.write(Zlib::GzipReader.new(open(config.xml_url)).read) } if config.xml_url
      end
      Cache.initialize_cache! config.xml_file
    end

    def cache_valid?
      Cache.valid?
    end

    def handset_from_device_id(id)
      Cache::HandsetsList.handset_by_device_id(id)
    end

    def handset_from_user_agent(user_agent)
      UserAgentMatcher.match(user_agent)
    end
  end
end

require 'wurfl_device/railtie' if defined?(Rails)
