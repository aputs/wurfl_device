require 'singleton'
require 'uri'

module WurflDevice
  class NullHandset
    include Singleton
    def self.id; 'root'; end
    def self.user_agent; ''; end
    def self.fall_back; nil; end
    def self.capabilities; nil; end
  end

  class Handset
    attr_reader :id

    def initialize(handset_id)
      raise ArgumentError, "invalid handset id #{handset_id}" if handset_id.empty?
      @id = handset_id
    end

    def user_agent
      @user_agent ||= capabilities.user_agent || ''
    end

    def fall_back
      @fall_back ||= (capabilities.fall_back_id ? (capabilities.fall_back_id == 'root' ? NullHandset : Cache.handsets[capabilities.fall_back_id]) : nil)
      raise CacheError, "fallback tree for `#{@id}` broken" if @fall_back.nil?
      @fall_back
    end

    def fall_back_tree
      return @fall_back_tree unless @fall_back_tree.nil?
      @fall_back_tree = Array.new
      f = fall_back
      while true
        break if f.nil?
        break if f.fall_back.nil?
        @fall_back_tree << f
        f = f.fall_back
      end
      @fall_back_tree
    end

    def capabilities
      build_from_cache! unless @capabilities
      @capabilities
    end

  private
    def build_from_cache!
      @user_agent = nil
      @fall_back = nil
      @capabilities = Capability.new
      actual_handset = Cache.storage.hgetall("#{self.class.name}.#{@id}")
      unless actual_handset.nil?
        actual_handset.each_pair do |n, v|
          if n =~ /(.+)\#(.+)/
            (@capabilities[$1] ||= Capability::Group.new)[$2] = capability_mapping_value($2, v)
          else
            @capabilities[n] = capability_mapping_value(n, v)
          end
        end
      end
      self
    end

    def capability_mapping_value(name, value)
      c_type = CapabilityMapping::CAPABILITY_TYPE_LOOKUP[name]
      warn("no capability mapping for `#{name}` => #{value}") unless c_type
      warn("capability already deprecated `#{name}`") if ((c_type & CapabilityMapping::CAPABILITY_TYPE_DEPRECATED) == CapabilityMapping::CAPABILITY_TYPE_DEPRECATED)
      return case c_type
      when CapabilityMapping::CAPABILITY_TYPE_URI
        URI(URI.escape(value))
      when CapabilityMapping::CAPABILITY_TYPE_BOOLEAN
        case
        when value == true || value =~ (/(true|t|yes|y|1)$/i)
          true
        when value == false || value.empty? || value =~ (/(false|f|no|n|0)$/i)
          false
        else
          raise ArgumentError, "invalid value for Boolean: `#{name} => #{value}`"
        end
      when CapabilityMapping::CAPABILITY_TYPE_INTEGER
        value.to_i
      when CapabilityMapping::CAPABILITY_TYPE_STRING
        value.to_s
      else
        value.to_s
      end
    end
  end
end