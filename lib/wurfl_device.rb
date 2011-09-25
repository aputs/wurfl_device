require 'etc'
require 'redis'

require 'wurfl_device/version'

module WurflDevice
  DB_INDEX = "7".freeze
  GENERIC = 'generic'

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
      device = Device.new(WurflDevice::GENERIC) unless device.is_valid?
      return device
    end

    def get_device_from_ua(user_agent)
      cached_device = db.hget("wurfl:user_agent_cache", user_agent)
      return Marshal::load(cached_device) if !cached_device.nil?
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

    def commify(n)
      n.to_s =~ /([^\.]*)(\..*)?/
      int, dec = $1.reverse, $2 ? $2 : ""
      while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
      end
      int.reverse + dec
    end

    # cache related
    def rebuild_user_agent_cache
      db.hkeys("wurfl:user_agent_cache").each do |user_agent|
        device = Device.new UserAgentMatcher.match(user_agent)
        db.hset("wurfl:user_agent_cache", user_agent, Marshal::dump(device))
      end
    end

    def clear_user_agent_cache
      db.keys("wurfl:user_agent_cache").each { |k| db.del k }
    end

    def clear_devices
      db.keys("wurfl:devices:*").each { |k| db.del k }
      %w(wurfl:version" wurfl:last_updated wurfl:user_agents wurfl:user_agents_sorted wurfl:is_initialized).each do |k|
        db.del k
      end
    end

    def initialized?
      return true if db.get("wurfl:is_initialized")
      initialize_cache
      loop do
        break if db.get("wurfl:is_initialized")
        sleep(0.1)
      end
      return true
    end

    def initialize_cache
      return unless db.setnx("wurfl:is_initializing", true)

      db.set("wurfl:is_initialized", false)
      (devices, version, last_updated) = XmlLoader.load_xml_file(XmlLoader.download_wurfl_xml_file) do |capabilities|
        device_id = capabilities.delete('id')
        next if device_id.nil?
        user_agent = capabilities.delete('user_agent')
        fall_back = capabilities.delete('fall_back')

        db.hset("wurfl:devices:#{device_id}", "id", device_id)
        db.hset("wurfl:devices:#{device_id}", "user_agent", user_agent)
        db.hset("wurfl:devices:#{device_id}", "fall_back", fall_back)
        capabilities.each_pair do |key, value|
          if value.is_a?(Hash)
            value.each_pair do |k, v|          
              db.hset("wurfl:devices:#{device_id}", "#{key.to_s}:#{k.to_s}", v)
            end
          else
            db.hset("wurfl:devices:#{device_id}", "#{key.to_s}", value)
          end
        end

        db.hset("wurfl:user_agents", user_agent, device_id)
        db.zadd("wurfl:user_agents_sorted", user_agent.length, user_agent)
      end

      db.set("wurfl:version", version)
      db.set("wurfl:last_updated", last_updated)
      db.set("wurfl:is_initialized", true)

      db.del("wurfl:is_initializing")
    end
  end
end
