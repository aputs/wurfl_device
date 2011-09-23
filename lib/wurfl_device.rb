require 'etc'
require 'redis'

require 'wurfl_device/version'

module WurflDevice
  DB_INDEX = "7".freeze
  GENERIC = 'generic'
  MAX_DEVICE_LEVEL = 10

  autoload :UI,                 'wurfl_device/ui'
  autoload :Capability,         'wurfl_device/capability'
  autoload :Device,             'wurfl_device/device'
  autoload :Handset,            'wurfl_device/handset'
  autoload :UserAgent,          'wurfl_device/user_agent'
  autoload :UserAgentMatcher,   'wurfl_device/user_agent_matcher'
  autoload :XmlLoader,          'wurfl_device/xml_loader'

  class WurflDeviceError < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end

  class CacheError    < WurflDeviceError; status_code(10); end

  class << self
    attr_writer :ui, :db

    def ui
      @ui ||= UI.new
    end

    def db
      @db ||= Redis.new(:db => DB_INDEX)
    end

    def tmp_dir
      File.join(Etc.systmpdir, 'wurfl_device')
    end

    def get_device(device_id)
      device = Device.new(device_id)
      return Device.new('generic') unless device.is_valid?
      return device
    end

    def get_device_from_ua(user_agent)
      cached_device = db.hget("wurfl:user_agent_cache", user_agent)
      return Marshal::load(cached_device) unless cached_device.nil?
      device_id = UserAgentMatcher.match(user_agent)
      device = get_device(device_id)
      db.hset("wurfl:user_agent_cache", user_agent, Marshal::dump(device))
      return device
    end

    def parse_string_value(value)
      return value if !value.is_a?(String)
      return false if value =~ /^false/i
      return true if value =~ /^true/i
      return value.to_i if (value == value.to_i.to_s)
      return value.to_f if (value == value.to_f.to_s)
      value
    end
  end
end
