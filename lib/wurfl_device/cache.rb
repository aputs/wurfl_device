require 'redis/connection/hiredis' unless defined?(FakeRedis)
require 'redis'

module WurflDevice
  module Cache
    class Entries
      class << self
        def clear
          entries.each { |key| Cache.storage.del(build_cache_id(key)) }
        end

        def set(id, key, value)
          Cache.storage.hset(build_cache_id(id), key, value)
        end

        def get(id, key)
          Cache.storage.hget(build_cache_id(id), key)
        end

        def keys(id)
          Cache.storage.hkeys(build_cache_id(id))
        end

        def keys_values(id)
          Cache.storage.hgetall(build_cache_id(id))
        end

        def entries
          entry_ids = Array.new
          Cache.storage.keys(build_cache_id('*')).each do |key|
            entry_ids << key.gsub(build_cache_id(''), '') rescue nil
          end
          entry_ids
        end

        def get_value(id)
          Cache.storage.get(build_cache_id(id))
        end

        def set_value(id, value)
          Cache.storage.set(build_cache_id(id), value)
        end

        def build_cache_id(id)
          "#{self.name}:#{id}"
        end
      end
    end

    class Devices < Entries; end
    class UserAgents < Entries; end
    class UserAgentsManufacturers < Entries; end

    class Status < Entries
      def self.version
        keys 'version' || ''
      end

      def self.last_updated
        get_value('last_updated') || ''
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
        Status.get_value('initialized').to_actual_value
      end

      def initialize_cache(xml_file)
        version_list = Array.new

        XmlLoader.load_xml_file(xml_file) do |capabilities|
          version = capabilities.delete(:version)
          version_list << version unless version.nil?

          device_id = capabilities.delete('id')
          next if device_id.nil? || device_id.empty?

          user_agent = capabilities.delete('user_agent')
          user_agent = Settings::GENERIC if user_agent.nil? || user_agent.empty?
          user_agent.strip!

          fall_back = capabilities.delete('fall_back')
          fall_back = '' if fall_back.nil?
          fall_back.strip!

          Devices.set device_id, 'id', device_id
          Devices.set device_id, 'user_agent', user_agent
          Devices.set device_id, 'fall_back', fall_back

          user_agent = UserAgent.new user_agent
          UserAgents.set user_agent, 'id', device_id
          unless user_agent =~ /^DO_NOT_MATCH/i
            UserAgentsManufacturers.set user_agent.manufacturer, user_agent, device_id 
          end

          capabilities.each_pair do |key, value|
            if value.is_a?(Hash)
              value.each_pair do |k, v|
                Devices.set device_id, "#{key.to_s}:#{k.to_s}", v
              end
            else
              Devices.set device_id, key.to_s, value
            end
          end
        end

        version_list.each do |ver|
          Status.set 'version', ver, Time.now
        end
        Status.set_value 'last_updated', Time.now
        Status.set_value 'initialized', true
      end

      def rebuild_user_agents
        UserAgents.clear
        UserAgentsManufacturers.clear
        Devices.entries.each do |device_id|
          device = Devices.keys_values device_id
          user_agent = UserAgent.new device['user_agent']
          UserAgents.set user_agent, 'id', device_id
          unless user_agent =~ /^DO_NOT_MATCH/i
            UserAgentsManufacturers.set user_agent.manufacturer, user_agent, device_id 
          end
        end
        Status.set_value 'last_updated', Time.now
      end

      def update_actual_capabilities(user_agent, capabilities)
        capabilities.each_pair do |key, value|
          if value.kind_of?(Hash)
            value.each_pair do |k, v|
              UserAgents.set user_agent, "#{key}:#{k}", v
            end
          elsif value.is_a?(Array)
            value.each_with_index do |v, i|
              UserAgents.set user_agent, "#{key}:#{i}", v
            end
          else
            UserAgents.set user_agent, key, value
          end
        end
      end

      def parse_actual_capabilities(actual_capabilities)
        capabilities = Capability.new

        actual_capabilities.each_pair do |key, value|
          if key =~ /^(.+)\:(\d+)$/i
            capabilities[$1] ||= Array.new
            capabilities[$1][$2.to_i] = value.to_actual_value
          elsif key =~ /^(.+)\:(.+)$/i
            capabilities[$1] ||= Capability.new
            capabilities[$1][$2] = value.to_actual_value
          else
            capabilities[key] = value.to_actual_value
          end
        end

        capabilities
      end

      def build_capabilities(device_id)
        capabilities = Capability.new
        actual_capabilities = Devices.keys_values(device_id)
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
                  capabilities[key][k] = v.to_actual_value
                end
              elsif value.is_a?(Array)
                capabilities[key] ||= Array.new
                capabilities[key] |= value.to_actual_value
              else
                capabilities[key] = value.to_actual_value
              end
            end
          end
        end

        actual_capabilities.each_pair do |key, value|
          if key =~ /^(.+)\:(.+)$/i
            capabilities[$1] ||= Capability.new
            capabilities[$1][$2] = value.to_actual_value
          else
            capabilities[key] = value.to_actual_value
          end
        end

        capabilities
      end
    end
  end
end
