require 'yaml'
require 'redis'

module WurflDevice
  class Device
    attr_accessor :capabilities

    def initialize(device_id=nil)
      raise WurflDevice::CacheError, "wurfl cache is not initialized" unless WurflDevice.is_initialized?
      if device_id.nil?
        @capabilities = WurflDevice.get_actual_device(WurflDevice::Constants::GENERIC)
      else
        @capabilities = build_device(device_id)
      end
      @capabilities['actual_device_root'] ||= ((@capabilities['user_agent'] !~ /^DO_NOT_MATCH/i) ? true : false)
    end

    def is_valid?
      return false if @capabilities.nil?
      return false if @capabilities.id.nil?
      return false if @capabilities.id.empty?
      return true
    end

    def is_generic?
      is_valid? && @capabilities.id !~ Regexp.new(WurflDevice::Constants::GENERIC, Regexp::IGNORECASE)
    end

    def build_device(device_id)
      capabilities = Capability.new
      device = WurflDevice.get_actual_device_raw(device_id)
      return nil if device.nil?

      capabilities['fall_back_tree'] ||= Array.new

      if !device['fall_back'].nil? && !device['fall_back'].empty? && device['fall_back'] != 'root'
        fall_back = build_device(device['fall_back'])
        unless fall_back.nil?
          capabilities['fall_back_tree'].unshift(fall_back['id'])
          fall_back.each_pair do |key, value|
            if value.kind_of?(Hash)
              capabilities[key] ||= Capability.new
              value.each_pair do |k, v|
                capabilities[key][k] = v
              end
            elsif value.is_a?(Array)
              capabilities[key] ||= Array.new
              capabilities[key] |= value
            else
              capabilities[key] = value
            end
          end
        end
      end

      device.each_pair do |key, value|
        if key =~ /^(.+)\:(.+)$/i
          capabilities[$1] ||= Capability.new
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
      return nil if @capabilities.nil?
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
