require 'singleton'
require 'uri'

module WurflDevice
  class Handset
    attr_reader :id, :capabilities

    MUTEX_LOCK = Mutex.new

    # NOTE Handset is not instantiated directly, instead should get from Cache::HandsetList
    def initialize(handset_id)
      raise ArgumentError, "invalid handset id #{handset_id}" unless handset_id
      @id = handset_id
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
    end

    def actual_device_root?
      capabilities.actual_device_root?
    end
    alias :actual_device_root :actual_device_root?

    def user_agent
      capabilities.user_agent
    end

    def fall_back
      f_b = Cache::HandsetsList.handset_by_device_id(capabilities.fall_back_id)
      raise CacheError, "cache error, fall_back chain for #{@id} broken!" unless f_b
      return f_b
    end

    def fall_back_tree
      fall_back_tree = Array.new
      f_b = fall_back
      while f_b
        fall_back_tree << f_b
        f_b = f_b.fall_back
      end
      fall_back_tree
    end

    def full_capabilities
      return @full_capabilities if @full_capabilities
      MUTEX_LOCK.synchronize do
        c_full = Capability.new
        fall_back_tree.unshift(self).reverse.collect { |h| h.capabilities }.each do |c|
          c.instance_variables.map do |n|
            v = c.instance_variable_get(n)
            if v.kind_of?(Capability::Group)
              v.instance_variables.map do |nn|
                c_full[n[1..n.id2name.length]] ||= Capability::Group.new
                c_full[n[1..n.id2name.length]][nn[1..nn.id2name.length]] = v.instance_variable_get(nn)
              end
            else
              c_full[n[1..n.id2name.length]] = v
            end
          end
        end
        @full_capabilities = c_full
      end
      @full_capabilities
    end

  private
    def capability_mapping_value(name, value)
      c_type = CapabilityMapping::CAPABILITY_TYPE_LOOKUP[name]
      warn("no capability mapping for `#{name}` => #{value}") unless c_type
      warn("capability already deprecated `#{name}`") if ((c_type & CapabilityMapping::CAPABILITY_TYPE_DEPRECATED) == CapabilityMapping::CAPABILITY_TYPE_DEPRECATED)
      return case c_type
      when CapabilityMapping::CAPABILITY_TYPE_URI
        value.to_s
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
        case
        when value == value.to_f.to_s
          value.to_f
        else
          value.to_i
        end
      when CapabilityMapping::CAPABILITY_TYPE_STRING
        value.to_s
      else
        value.to_s
      end
    end

    class NullHandset
      include Singleton
      def self.id; 'root'; end
      def self.user_agent; nil; end
      def self.fall_back; nil; end
      def self.fall_back_tree; nil; end
      def self.capabilities; nil; end
    end
  end
end