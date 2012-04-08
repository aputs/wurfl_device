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
    LOCKED_KEY_NAME = ".locked-#{self.name}"

    class << self
      attr_writer :storage

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
          storage.keys("#{self.name.split('::').first}*").each { |n| storage.del n }

          lock_extender = Thread.new {
            loop {
              sleep(DB_LOCK_EXPIRES * 0.90)
              extend_lock(LOCKED_KEY_NAME, DB_LOCK_EXPIRES)
            }
          }

          capabilities_to_group = Hash.new
          capabilities_groups = Hash.new

          raise XMLFileError, "Invalid xml file! `#{filename}`" unless File.exists?(filename)
          reader = LibXML::XML::Reader.file(filename)
          current_device = nil
          current_group = nil
          while reader.read
            if reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
              case reader.name
              when 'device'
                current_device = Hash.new
                current_device['id'] = reader['id']
                current_device['user_agent'] = reader['user_agent']
                current_device['fall_back_id'] = reader['fall_back']
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
                  handset_id = current_device.delete('id')
                  hash_values = Array.new ['id', handset_id]
                  current_device.each_pair do |n, v|
                    if v.kind_of?(Hash)
                      v.each_pair { |k, val| hash_values << "#{n}##{k}"<< val }
                    else
                      hash_values << n << v
                    end
                  end
                  storage.hmset "#{Handset.name}.#{handset_id}", *hash_values
                end

                current_device = nil
                current_group = nil
              when 'group'
                current_group = nil
              end
            end
          end
          reader.close

          @@handsets = nil
          @@handset_capabilities = nil

          raise 'error initializing cache! invalid capabilities' if capabilities_groups.empty?
          capabilities_groups.keys.each {|k| storage.sadd HANDSETS_CAPABILITIES_GROUPS_KEY_NAME, k }
          storage.hmset HANDSETS_CAPABILITIES_KEY_NAME, *capabilities_to_group.each_with_object([]) { |o, a| a << o }.flatten
          storage.keys("#{Handset.name}*").sort.each_with_index { |n, i| storage.sadd HANDSETS_KEY_NAME, n.split('.').last }

          storage.set(INITIALIZED_KEY_NAME, Time.now)

          lock_extender.kill
        end

        raise CacheError, 'error initializing cache!' unless valid?
      end

      def handsets
        @@handsets ||= Hash[*storage.smembers(HANDSETS_KEY_NAME).collect { |n| [n, Handset.new(n)] }.flatten]
        raise CacheError, 'cache error! handsets list empty.' if @@handsets.empty?
        @@handsets
      end

      def handsets_capabilities
        @@handsets_capabilities ||= storage.hgetall(HANDSETS_CAPABILITIES_KEY_NAME)
        raise CacheError, 'cache error! handsets capabilities list.' if @@handsets_capabilities.empty?
        @@handsets_capabilities
      end

      def handsets_capabilities_groups
        @@handsets_capabilities_groups ||= storage.smembers(HANDSETS_CAPABILITIES_GROUPS_KEY_NAME)
        raise CacheError, 'cache error! handsets capabilities groups list empty.' if @@handsets_capabilities_groups.empty?
        @@handsets_capabilities_groups
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
