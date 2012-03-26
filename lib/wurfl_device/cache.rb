require 'redis/connection/hiredis' unless defined?(FakeRedis)
require 'redis'
require 'redis/lock'

module WurflDevice
  module Cache
    DB_INDEX = 7
    DB_LOCK_TIMEOUT = 10
    DB_LOCK_EXPIRES = 60
    INITIALIZED_KEY_NAME = self.name + ".initialized"
    LOCKED_KEY_NAME = self.name + ".locked"

    @@storage = Redis.new(:db => DB_INDEX)

    class << self
      def get(id)
        cache_value = @@storage.get(id)
        return Marshal.load(cache_value) unless cache_value.nil?
        return nil
      end
      alias :[] :get

      def set(id, value)
        return @@storage.set(id, Marshal.dump(value))
      end
      alias :[]= :set

      def del(id)
        return @@storage.del(id)
      end

      def valid?
        !@@storage.get(INITIALIZED_KEY_NAME).nil?
      end

      def initialize_cache!
        @@storage.lock_for(LOCKED_KEY_NAME, DB_LOCK_EXPIRES, DB_LOCK_TIMEOUT) do
          del(INITIALIZED_KEY_NAME)

          set(INITIALIZED_KEY_NAME, Time.now)
        end
      end
    end
  end
end

=begin
  module Cache
    class Entries
      class << self
        def clear
          entries.each { |key| Cache.storage.del(build_cache_id(key)) }
        end

        def set(id, value)
          Cache.storage.set(build_cache_id(id), value)
        end

        def get(id)
          Cache.storage.get(build_cache_id(id))
        end

        def del(id)
          Cache.storage.del(build_cache_id(id))
        end

        def hset(id, key, value)
          Cache.storage.hset(build_cache_id(id), key, value)
        end

        def hget(id, key)
          Cache.storage.hget(build_cache_id(id), key)
        end

        def hkeys(id)
          Cache.storage.hkeys(build_cache_id(id))
        end

        def hgetall(id)
          Cache.storage.hgetall(build_cache_id(id))
        end

        def entries
          entry_ids = Array.new
          Cache.storage.keys(build_cache_id('*')).each do |key|
            entry_ids << key.gsub(build_cache_id(''), '') rescue nil
          end
          entry_ids
        end

        def build_cache_id(id)
          "#{self.name}:#{id}"
        end
      end
    end

    class Devices < Entries; end
    class UserAgents < Entries; end
    class UserAgentsMatched < Entries; end
    class UserAgentsManufacturers < Entries; end

    class Status < Entries
      def self.last_updated
        get('last_updated') || ''
      end

      def self.version
        hkeys 'version'
      end

      def self.initialized?
        get 'initialized'
      end

      def self.initialize!
        set 'initialized', 1
      end

      def self.uninitialize!
        del 'initialized'
      end
    end

    class << self
      attr_writer :storage

      def storage
        @storage ||= Redis.new(:db => 7)
      end

      def clear
        Status.clear
        Devices.clear
        UserAgents.clear
        UserAgentsManufacturers.clear
      end

      def initialized?
        status = Status.initialized?
        return false if status.nil?
        return false if status.empty?
        return false if status.to_i == 0
        return true
      end

      def initialize_cache(xml_file)
        version_list = Array.new

        Status.uninitialize!
        XmlLoader.load_xml_file(xml_file) do |capabilities|
          version = capabilities.delete(:version)
          version_list << version unless version.nil?

          device_id = capabilities['id']
          next if device_id.nil? || device_id.empty?

          user_agent = capabilities['user_agent']
          user_agent = Settings::GENERIC if user_agent.nil? || user_agent.empty?
          user_agent.strip!

          fall_back = capabilities['fall_back']
          fall_back = '' if fall_back.nil?
          fall_back.strip!

          user_agent = UserAgent.new user_agent
          UserAgents.set user_agent, device_id
          unless user_agent =~ /^DO_NOT_MATCH/i
            UserAgentsManufacturers.hset user_agent.manufacturer, user_agent, device_id
          end

          Devices.set device_id, capabilities.to_msgpack
        end

        version_list.each do |ver|
          Status.hset 'version', ver, 1
        end
        Status.set 'last_updated', Time.now

        Status.initialize!
      end

      def rebuild_user_agents
        UserAgents.clear
        UserAgentsManufacturers.clear
        Devices.entries.each do |device_id|
          device = MessagePack.unpack(Devices.get(device_id).force_encoding('US-ASCII'))
          user_agent = UserAgent.new device['user_agent']
          UserAgents.set user_agent, device_id
          unless user_agent =~ /^DO_NOT_MATCH/i
            UserAgentsManufacturers.hset user_agent.manufacturer, user_agent, device_id
          end
        end
        Status.set 'last_updated', Time.now
      end

      def update_actual_capabilities(user_agent, capabilities)
        capabilities.each_pair do |key, value|
          if value.kind_of?(Hash)
            value.each_pair do |k, v|
              UserAgents.set user_agent, "#{key}:#{k}", MessagePack.pack(v)
            end
          else
            if ['user_agent', 'fall_back', 'id'].include?(key)
              UserAgents.set user_agent, key, value
            else
              UserAgents.set user_agent, key, MessagePack.pack(value)
            end
          end
        end
      end

      def build_capabilities(device_id)
        capabilities = Capability.new

        actual_capabilities = MessagePack.unpack(Devices.get(device_id).force_encoding('US-ASCII')) rescue nil

        return capabilities if actual_capabilities.nil?

        capabilities['fall_back_tree'] ||= Array.new

        if !actual_capabilities['fall_back'].nil? && !actual_capabilities['fall_back'].empty? && actual_capabilities['fall_back'] != 'root'
          fall_back = build_capabilities(actual_capabilities['fall_back'])
          if !fall_back.nil? && !fall_back['id'].nil? && !fall_back['id'].empty?
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

        actual_capabilities.each_pair do |key, value|
          if value.kind_of?(Hash)
            capabilities[key] ||= Capability.new
            value.each_pair do |k, v|
              capabilities[key][k] = v
            end
          else
            capabilities[key] = value
          end
        end

        capabilities
      end
    end
  end
=end
