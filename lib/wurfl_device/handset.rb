require 'singleton'

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
      @id = handset_id
    end

    def user_agent
      @user_agent ||= capabilities.user_agent || 'generic'
    end

    def fall_back
      @fall_back ||= (capabilities.fall_back ? (capabilities.fall_back == 'root' ? NullHandset : Cache.handsets[capabilities.fall_back]) : nil)
      raise CacheError, "fallback tree for #{@id} broken" if @fall_back.nil?
      @fall_back
    end

    def fall_back_tree
      return @fall_back_tree unless @fall_back_tree.nil?
      @fall_back_tree = Array.new
      f = fall_back; while f.id != 'root'; @fall_back_tree << f; f = f.fall_back; end
      @fall_back_tree
    end

    def capabilities
      build_from_cache! unless @capabilities
      @capabilities
    end

    def build_from_cache!
      @user_agent = nil
      @fall_back = nil
      @capabilities = Capability.new
      actual_handset = Cache.storage.hgetall("#{self.class.name}.#{@id}")
      unless actual_handset.nil?
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