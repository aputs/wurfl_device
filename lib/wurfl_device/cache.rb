require 'redis'
require 'libxml'

module WurflDevice
  module Cache
    DB_LOCK_TIMEOUT = 10
    DB_LOCK_EXPIRES = 120
    INITIALIZED_KEY_NAME = "#{self.name}.initialized"
    LOCKED_KEY_NAME = ".locked-#{self.name}"
    MUTEX_FOR_STORAGE = Mutex.new

    module HandsetsList
      MUTEX_LOCK = Mutex.new

      def self.handsets_and_user_agents
        return @handsets_and_user_agents if @handsets_and_user_agents
        MUTEX_LOCK.synchronize do
          raise CacheError, 'error cache not initialized' unless Cache.valid?
          @handsets_and_user_agents ||= Cache.storage.hgetall(self.name)
        end
        @handsets_and_user_agents
      end

      def self.handset_by_device_id(device_id)
        return Handset::NullHandset if device_id == 'root'
        return nil unless handsets_and_user_agents.values.include?(device_id)
        MUTEX_LOCK.synchronize do
          @handsets_cache ||= Hash.new
          @handsets_cache[device_id] ||= Handset.new(device_id)
        end
        @handsets_cache[device_id]
      end

      def self.handset_by_user_agent(ua)
        device_id = handsets_and_user_agents[ua]
        return nil unless device_id
        return handset_by_device_id(device_id)
      end

      def self.count
        handsets_and_user_agents.keys.count
      end

      def self.clear
        MUTEX_LOCK.synchronize do
          @handsets_and_user_agents = nil
          @handsets_cache = nil
        end
      end
    end

    module CapabilityList
      MUTEX_LOCK = Mutex.new

      def self.capabilities
        MUTEX_LOCK.synchronize do
          @capabilities ||= Cache.storage.hgetall(self.name)
        end
      end

      def self.groups
        capabilities.values.uniq
      end

      def self.clear
        MUTEX_LOCK.synchronize do
          @capabilities = nil
        end
      end
    end

    module UserAgentsMatchers
      MUTEX_LOCK = Mutex.new

      def self.user_agent_matchers
        Cache.storage.keys("#{self.name}.*").collect { |c| c.split('.').last }
      end

      def self.user_agent_matched
        Cache.storage.hgetall("#{self.name}#cached")
      end

      def self.user_agents_for_brand(brand)
        return @user_agents_for_brand[brand] if @user_agents_for_brand && @user_agents_for_brand[brand]
        MUTEX_LOCK.synchronize do
          raise CacheError, 'error cache not initialized' unless Cache.valid?
          @user_agents_for_brand ||= Hash.new
          @user_agents_for_brand[brand] = Cache.storage.hkeys("#{self.name}.#{brand}").sort
        end
        @user_agents_for_brand[brand]
      end

      def self.user_agent_cached_get(ua)
        @user_agent_cached ||= Hash.new
        return @user_agent_cached[ua] if @user_agent_cached[ua]
        cached = Cache.storage.hget "#{self.name}#cached", ua
        return nil unless cached
        @user_agent_cached[ua] ||= cached
      end

      def self.user_agent_cached_set(ua, device_id)
        Cache.storage.hset "#{self.name}#cached", ua, device_id
      end

      def self.clear
        MUTEX_LOCK.synchronize do
          @user_agents_for_brand = nil
          @user_agent_cached = nil
        end
      end
    end

    @storage = nil

    class << self
      attr_reader :storage

      def disconnect!
        MUTEX_FOR_STORAGE.synchronize do
          @storage = nil
        end
      end

      def storage
        return @storage if @storage
        MUTEX_FOR_STORAGE.synchronize do
          @storage ||= Redis.new(
            :host => WurflDevice.config.redis_host,
            :port => WurflDevice.config.redis_port,
            :path => WurflDevice.config.redis_path,
            :db => WurflDevice.config.redis_db
          )
        end
        @storage
      end

      def valid?
        !storage.get(INITIALIZED_KEY_NAME).nil?
      end

      def last_updated
        storage.get(INITIALIZED_KEY_NAME)
      end

      def initialize_cache!(filename)
        raise XMLFileError, "Invalid xml file! `#{filename}`" unless File.exists?(filename)

        store_device = Proc.new do |device|
          capabilities_list = device.collect { |c| c[1].kind_of?(Hash) ? c[1].collect { |cc| ["#{c[0]}##{cc[0]}", cc[1]] } : c }.flatten.compact
          capabilities_key_list = device.select { |k, v| v.kind_of?(Hash) }.collect { |c| c[1].collect { |cc| [cc[0], c[0]] } }.flatten.compact
          capabilities_group_list = device.select { |k, v| v.kind_of?(Hash) }.collect { |c| [c[0], '@'] }.flatten.compact
          storage.hset HandsetsList.name, device['user_agent'], device['id']
          storage.hmset Handset.name + "." + device['id'], *capabilities_list unless capabilities_list.empty?
          storage.hmset CapabilityList.name, *capabilities_key_list unless capabilities_key_list.empty?
          unless device['user_agent'] =~ /DO_NOT_MATCH/
            matcher = UserAgent.classify(device['user_agent'])
            storage.hset UserAgentsMatchers.name + "." + matcher, device['user_agent'], device['id']
          end
        end

        cache_was_initialized = false
        lock_for(LOCKED_KEY_NAME, DB_LOCK_EXPIRES, DB_LOCK_TIMEOUT) do
          storage.del(INITIALIZED_KEY_NAME)
          storage.del *storage.keys("#{self.name.split('::').first}*") rescue nil

          reader = LibXML::XML::Reader.file(filename)
          current_device = current_group = nil
          while reader.read
            case reader.node_type
            when LibXML::XML::Reader::TYPE_ELEMENT
              case reader.name
              when 'device'
                store_device.call(current_device) if current_device

                device_id = reader['id']
                user_agent = reader['user_agent'] || ''
                user_agent = 'generic' if user_agent.empty?
                fall_back_id = reader['fall_back'] || ''
                actual_device_root = reader['actual_device_root'] || 'false'
                current_device = Hash[
                  'id' => device_id,
                  'user_agent' => UserAgent.new(user_agent),
                  'fall_back_id' => fall_back_id, 'actual_device_root' => actual_device_root
                  ] unless device_id.empty?
              when 'group'
                unless current_device.nil?
                  current_group = reader['id']
                  current_device[current_group] ||= Hash.new
                end
              when 'capability'
                unless current_group.nil?
                  current_device[current_group][reader['name']] = reader['value']
                end
              end
            when LibXML::XML::Reader::TYPE_END_ELEMENT
              case reader.name
              when 'device'
                store_device.call(current_device) if current_device
                current_device = current_group = nil
              when 'group'
                current_group = nil
              end
            end
          end
          reader.close

          cache_was_initialized = true
          storage.set(INITIALIZED_KEY_NAME, Time.now)

          HandsetsList.clear
          CapabilityList.clear
          UserAgentsMatchers.clear
        end

        raise CacheError, 'error initializing cache!' unless cache_was_initialized
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
