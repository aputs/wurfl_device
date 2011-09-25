require 'yaml'
require 'redis'

module WurflDevice
  class Device
    attr_accessor :capabilities

    def initialize(device_id=nil)
      @capabilities = nil
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
    def get_device(device_id)
      capabilities = Hash.new

      device = WurflDevice.db.hgetall("wurfl:devices:#{device_id}")
      return capabilities if device.nil?

      capabilities['fall_back_tree'] ||= Array.new
      if device.has_key?('fall_back') && !device['fall_back'].empty? && device['fall_back'] != 'root' && device['id'] != WurflDevice::GENERIC
        fall_back = get_device(device['fall_back'])
        if fall_back.is_a?(Hash)
          fall_back.each_pair do |key, value|
            if value.is_a?(Hash)
              capabilities[key] ||= Hash.new
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
        capabilities['fall_back_tree'].unshift fall_back['id']
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
