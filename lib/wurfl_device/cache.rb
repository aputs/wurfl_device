require 'redis'
require 'libxml'

module WurflDevice
  module Cache
    DB_LOCK_TIMEOUT = 10
    DB_LOCK_EXPIRES = 60
    INITIALIZED_KEY_NAME = "#{self.name}.initialized"
    HANDSETS_KEY_NAME = "#{self.name}.handsets"
    HANDSETS_CAPABILITIES_KEY_NAME = "#{self.name}.handset_capabilities"
    HANDSETS_CAPABILITIES_GROUPS_KEY_NAME = "#{self.name}.handset_capabilities_groups"
    HANDSETS_USERAGENTS_MATCHERS_KEY_NAME = "#{self.name}.user_agents_matchers"
    HANDSETS_USERAGENTS_CACHED_KEY_NAME = "#{self.name}.user_agents_cached"
    LOCKED_KEY_NAME = ".locked-#{self.name}"

    class << self
      attr_writer :storage

      def disconnect!
        @@storage = nil
      end

      def storage
        @@storage ||= Redis.new(
          :host => WurflDevice.config.redis_host,
          :port => WurflDevice.config.redis_port,
          :path => WurflDevice.config.redis_path,
          :db => WurflDevice.config.redis_db
        )
      end

      def valid?
        !storage.get(INITIALIZED_KEY_NAME).nil?
      end

      def initialize_cache!(filename)
        lock_for(LOCKED_KEY_NAME, DB_LOCK_EXPIRES, DB_LOCK_TIMEOUT) do
          storage.del(INITIALIZED_KEY_NAME)

          @@handsets = nil
          @@handset_capabilities = nil
          @@handsets_capabilities_groups = nil
          @@user_agents = nil
          @@user_agent_matchers = nil

          storage.keys("#{self.name.split('::').first}*").each { |n| storage.del n }

          # TODO replace with a lighter version (fiber/actor)
          lock_extender = Thread.new {
            loop {
              sleep(DB_LOCK_EXPIRES * 0.90)
              extend_lock(LOCKED_KEY_NAME, DB_LOCK_EXPIRES)
            }
          }

          capabilities_to_group = Hash.new
          capabilities_groups = Hash.new
          handsets_list = Hash.new

          raise XMLFileError, "Invalid xml file! `#{filename}`" unless File.exists?(filename)
          reader = LibXML::XML::Reader.file(filename)
          current_device = nil
          current_group = nil
          while reader.read
            if reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
              case reader.name
              when 'device'
                device_id = reader['id']
                user_agent = reader['user_agent'] || ''
                user_agent = 'generic' if user_agent.empty?
                fall_back_id = reader['fall_back'] || ''
                unless device_id.empty?
                  current_device = Hash['id' => device_id, 'user_agent' => UserAgent.new(user_agent), 'fall_back_id' => fall_back_id]
                  handsets_list[device_id] ||= current_device['user_agent']
                end
              when 'group'
                unless current_device.nil?
                  current_group = reader['id']
                  capabilities_groups[current_group] = 1
                  current_device[current_group] ||= Hash.new
                end
              when 'capability'
                unless current_group.nil?
                  current_device[current_group][reader['name']] = reader['value']
                  capabilities_to_group[reader['name']] = current_group
                end
              end
            elsif reader.node_type == LibXML::XML::Reader::TYPE_END_ELEMENT
              case reader.name
              when 'device'
                unless current_device.nil?
                  storage.hmset "#{Handset.name}.#{current_device['id']}", *current_device.collect { |c| c[1].kind_of?(Hash) ? c[1].collect { |cc| ["#{c[0]}##{cc[0]}", cc[1]] } : c }.flatten
                  current_device = nil
                end
                current_group = nil
              when 'group'
                current_group = nil
              end
            end
          end
          reader.close

          raise 'error initializing cache! capabilities group invalid' if capabilities_groups.empty?
          raise 'error initializing cache! handset/user agent list for matching invalid' if handsets_list.empty?
          storage.hmset HANDSETS_CAPABILITIES_GROUPS_KEY_NAME, *capabilities_groups.flatten
          storage.hmset HANDSETS_CAPABILITIES_KEY_NAME, *capabilities_to_group.flatten
          storage.hmset HANDSETS_KEY_NAME, *handsets_list.flatten
          handsets_list.each_with_object({}) { |d, h| (c = d[1].classify; h[c] ||= Hash.new; h[c][d[1]] = d[0]) unless d[1] =~ /DO_NOT_MATCH/ }.each { |k, v| storage.hmset "#{HANDSETS_USERAGENTS_MATCHERS_KEY_NAME}_#{k}", *v.flatten }

          storage.set(INITIALIZED_KEY_NAME, Time.now)

          lock_extender.kill
        end

        raise CacheError, 'error initializing cache!' unless valid?
      end

      def handsets
        @@handsets ||= Hash[*storage.hkeys(HANDSETS_KEY_NAME).collect { |n| [n, Handset.new(n)] }.flatten]
        raise CacheError, 'cache error! handsets list empty.' if @@handsets.empty?
        @@handsets
      end

      def handsets_capabilities
        @@handsets_capabilities ||= storage.hgetall(HANDSETS_CAPABILITIES_KEY_NAME)
        raise CacheError, 'cache error! handsets capabilities list.' if @@handsets_capabilities.empty?
        @@handsets_capabilities
      end

      def handsets_capabilities_groups
        @@handsets_capabilities_groups ||= storage.hkeys(HANDSETS_CAPABILITIES_GROUPS_KEY_NAME)
        raise CacheError, 'cache error! handsets capabilities groups list empty.' if @@handsets_capabilities_groups.empty?
        @@handsets_capabilities_groups
      end

      def user_agents
        @@user_agents ||= Hash[*storage.hgetall(HANDSETS_KEY_NAME).collect { |n| [n[1], handsets[n[0]]] }.flatten ]
        raise CacheError, 'cache error! user agents list empty.' if @@user_agents.empty?
        @@user_agents
      end

      def user_agent_matchers(matcher)
        @@user_agent_matchers ||= Hash.new
        @@user_agent_matchers[matcher] ||= storage.hgetall("#{HANDSETS_USERAGENTS_MATCHERS_KEY_NAME}_#{matcher}")
      end

      def user_agent_cached(user_agent)
        storage.hget(HANDSETS_USERAGENTS_CACHED_KEY_NAME, user_agent)
      end

      def lock_for(key, expires=60, timeout=10)
        if lock(key, expires, timeout)
          response = yield if block_given?
          unlock(key)
          return response
        end
      end

    private
      def lock(key, expires, timeout)
        while timeout >= 0
          expiry_time = Time.now.to_i + expires + 1
          return true if storage.setnx(key, expiry_time)
          current_value = storage.get(key).to_i
          sleep(2)
          return true if current_value && current_value < Time.now.to_i && storage.getset(key, expiry_time).to_i == current_value
          timeout -= 1
        end
        raise LockTimeout, 'Timeout whilst waiting for lock'
      end

      def extend_lock(key, expires)
        expiry_time = Time.now.to_i + expires + 1
        storage.set(key, expiry_time)
      end

      def unlock(key)
        storage.del(key)
      end
    end
  end
end
