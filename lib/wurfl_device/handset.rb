require 'singleton'

module WurflDevice
  class NullHandset
    include Singleton
    def self.id; 'root'; end
    def self.user_agent; ''; end
    def self.fall_back; nil; end
    def self.capabilities; Capability.new; end
  end

  class Handset
    attr_reader :id, :capabilities

    def initialize(handset_id)
      @id = handset_id
      @capabilities = Capability.new
    end

    def user_agent
      build_from_cache! unless capabilities['user_agent']
      @user_agent ||= capabilities['user_agent'] || 'generic'
    end

    def fall_back
      build_from_cache! unless capabilities['fall_back_id']
      @fall_back ||= (capabilities['fall_back_id'] ? (capabilities['fall_back_id'] == 'root' ? NullHandset : Cache.handsets[capabilities['fall_back_id']]) : NullHandset)
    end

    def store_to_cache
      hash_values = Array.new
      hash_values << 'id' << @id

      capabilities.each_pair do |n, v|
        if v.kind_of?(Hash)
          v.each_pair { |k, val| hash_values << "#{n}##{k}"<< val }
        elsif v.kind_of?(Array)
          v.each_index { |k, val| hash_values << "#{n}@#{k}" << val }
        else
          hash_values << n << v
        end
      end
      Cache.storage.hmset "#{self.class.name}.#{@id}", *hash_values
      self
    end

    def build_from_cache!
      @user_agent = nil
      @fall_back = nil
      @capabilities = Capability.new
      actual_handset = Cache.storage.hgetall("#{self.class.name}.#{@id}")
      unless actual_handset.nil?
        @id = actual_handset.delete('id')
        actual_handset.each_pair do |n, v|
          v = actual_value(v)
          if n =~ /(.+)\#(.+)/
            (@capabilities[$1] ||= Capability::Group.new)[$2] = v
          elsif n =~ /(.+)\@(.+)/
            (@capabilities[$1.to_i] ||= Array.new)[$2] = v
          else
            @capabilities[n] = v
          end
        end
      end
      self
    end

  private
    def actual_value(v)
      return case
      when v =~ /^false$/i
        false
      when v =~ /^true$/i
        true
      else
        v
      end
    end
  end
end