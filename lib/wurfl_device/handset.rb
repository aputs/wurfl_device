require 'singleton'

module WurflDevice
  class Handset
    attr_reader :id, :user_agent, :fall_back, :capabilities

    def initialize(id, user_agent='generic', fall_back='root')
      raise ArgumentError, 'invalid fall_back specified' if fall_back.empty?
      @id = id
      @user_agent = user_agent
      @fall_back = NullHandset
      @fall_back = Handset.new(fall_back) unless fall_back == 'root'
      @capabilities = Capability.new
    end

    def store_to_cache
      hash_values = Array.new
      hash_values << 'id'
      hash_values << id
      hash_values << 'user_agent'
      hash_values << user_agent
      hash_values << 'fall_back'
      hash_values << fall_back.id

      capabilities.each_pair do |n, v|
        if v.kind_of?(Hash)
          v.each_pair do |k, val|
            hash_values << "#{n}##{k}"
            hash_values << val
          end
        elsif v.kind_of?(Array)
          v.each_index do |k, val|
            hash_values << "#{n}@#{k}"
            hash_values << val
          end
        else
          hash_values << n
          hash_values << v
        end
      end
      Cache.storage.hmset "#{self.class.name}.#{@id}", *hash_values
    end

    def retrieve_from_cache!(id)
      actual_handset = Cache.storage.hgetall("#{self.class.name}.#{id}")
      return NullHandset if actual_handset.empty?
      @id = actual_handset.delete('id')
      @user_agent = actual_handset.delete('user_agent')
      @fall_back = Handset.new(actual_handset.delete('fall_back'))
      @capabilities = Capability.new
      actual_handset.each_pair do |n, v|
        if n =~ /(.+)\#(.+)/
          @capabilities[$2] ||= Capability::Group.new
          @capabilities[$2] = v
        elsif n =~ /(.+)\@(.+)/
          @capabilities[$2] ||= Array.new
          @capabilities[$2] = v
        else
          @capabilities[n] = v
        end
      end
      self
    end

    def self.[](id)
      self.new(id).retrieve_from_cache!(id)
    end

    class NullHandset
      include Singleton
      def self.id; 'root'; end
      def self.user_agent; 'generic'; end
      def self.fall_back; ''; end
      def self.capabilities; Capability.new; end
    end
  end
end