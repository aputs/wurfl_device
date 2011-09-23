require 'yaml'
require 'redis'

module WurflDevice
  class Device
    attr_accessor :capabilities

    def self.initialized?
      return true if WurflDevice.db.get("wurfl:devices:is_initialized")
      initialize_cache
      loop do
        break if WurflDevice.db.get("wurfl:devices:is_initialized")
        sleep(0.1)
      end
      return true
    end

    def self.clear_cache
      WurflDevice.db.keys("wurfl:*").each { |k| WurflDevice.db.del k }
    end

    def self.initialize_cache
      return unless WurflDevice.db.setnx("wurfl:is_initializing", true)

      WurflDevice.db.set("wurfl:devices:is_initialized", false)
      (devices, version, last_updated) = XmlLoader.load_xml_file(XmlLoader.download_wurfl_xml_file) do |capabilities|
        device_id = capabilities.delete('id')
        next if device_id.nil?
        user_agent = capabilities.delete('user_agent')
        fall_back = capabilities.delete('fall_back')

        WurflDevice.db.hset("wurfl:devices:#{device_id}", "id", device_id)
        WurflDevice.db.hset("wurfl:devices:#{device_id}", "user_agent", user_agent)
        WurflDevice.db.hset("wurfl:devices:#{device_id}", "fall_back", fall_back)
        capabilities.each_pair do |key, value|
          if value.is_a?(Hash)
            value.each_pair do |k, v|          
              WurflDevice.db.hset("wurfl:devices:#{device_id}", "#{key.to_s}:#{k.to_s}", v)
            end
          else
            WurflDevice.db.hset("wurfl:devices:#{device_id}", "#{key.to_s}", value)
          end
        end

        WurflDevice.db.hset("wurfl:user_agents", user_agent, device_id)
        WurflDevice.db.zadd("wurfl:user_agents_sorted", user_agent.length, user_agent)
      end

      WurflDevice.db.set("wurfl:devices:version", version)
      WurflDevice.db.set("wurfl:devices:last_updated", last_updated)
      WurflDevice.db.set("wurfl:devices:is_initialized", true)

      WurflDevice.db.del("wurfl:is_initializing")
    end

    def initialize(device_id=nil)
      raise CacheError, "can't initialize wurfl_device cached" unless Device.initialized?
      build_device(device_id) unless device_id.nil?
    end

    def build_device(device_id)
      device_capabilities = get_device(device_id)

      @capabilities = Capability.new
      device_capabilities.each_pair do |key, value|
        if value.is_a? (Hash)
          @capabilities[key] = Capability.new(value)
        else
          @capabilities[key] = value
        end
      end
    end

    def is_valid?
      return false if @capabilities.nil?
      @capabilities.has_key?('id') && !@capabilities['id'].empty?
    end

    def is_generic?
      is_valid? && @capabilities['id'] !~ /generic/i
    end

  protected
    def get_device(device_id, level=0)
      capabilities = Hash.new

      device = WurflDevice.db.hgetall("wurfl:devices:#{device_id}")
      return capabilities if device.nil?

      capabilities['fall_back_tree'] ||= Array.new
      if level < WurflDevice::MAX_DEVICE_LEVEL && device.has_key?('fall_back') && !device['fall_back'].empty? && device['fall_back'] != 'root'
        fallback = get_device(device['fall_back'], level + 1)
        capabilities.merge!(fallback) if fallback
        capabilities['fall_back_tree'] << device['fall_back'] unless device['fall_back'].empty?
      end

      device.each_pair do |key, value|
        if key =~ /^(.+)\:(.+)$/i
          capabilities[$1] ||= Hash.new
          capabilities[$1][$2] = WurflDevice.parse_string_value(value)
        else
          capabilities[key] = WurflDevice.parse_string_value(value)
        end
      end

      capabilities
    end

    # Magic predicates
    # slower than going directly to capabilities
    def method_missing(method, *args, &block)
      meth = method.to_s
      meth.gsub!(/\?/, '')
      return @capabilities.send(method, args, block) if @capabilities.has_key?(meth)
      @capabilities.each_pair do |key, value|
        if value.is_a?(Hash)
          return value.send(method, args, block) if value.has_key?(meth)
        end
      end
      return nil
    end
  end
end
