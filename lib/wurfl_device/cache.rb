require 'redis'
require 'libxml'

module WurflDevice
  module Cache
    DB_INDEX = 7
    DB_LOCK_TIMEOUT = 10
    DB_LOCK_EXPIRES = 60
    INITIALIZED_KEY_NAME = "#{self.name}.initialized"
    HANDSET_KEY_NAME = "#{self.name}.handsets"
    LOCKED_KEY_NAME = ".locked-#{self.name}"

    class << self
      attr_reader :storage

      def storage
        @@storage ||= Redis.new(:db => DB_INDEX)
      end

      def valid?
        !storage.get(INITIALIZED_KEY_NAME).nil?
      end
      alias :initialized? :valid?

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

          doc = ::LibXML::XML::Document.file(filename)
          doc.find('//devices/device').each do |p|
            d_info = p.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
            handset_id = d_info['id']
            next if handset_id.empty?
            capabilities = Capability.new
            capabilities['user_agent'] = d_info['user_agent']
            capabilities['fall_back_id'] = d_info['fall_back']
            p.each_element do |g|
              g_info = g.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
              c_group = Capability::Group.new
              g_name = g_info['id']
              g.each_element do |c|
                c_info = c.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
                c_group[c_info['name']] = c_info['value']
                capabilities_to_group[c_info['name']] ||= g_name
              end
              capabilities[g_name] = c_group
            end

            hash_values = Array.new ['id', handset_id]

            capabilities.each_pair do |n, v|
              if v.kind_of?(Hash)
                v.each_pair { |k, val| hash_values << "#{n}##{k}"<< val }
              elsif v.kind_of?(Array)
                v.each_index { |k, val| hash_values << "#{n}@#{k}" << val }
              else
                hash_values << n << v
              end
            end
            storage.hmset "#{Handset.name}.#{handset_id}", *hash_values
          end

          @@handsets = nil
          @@handset_capabilities = nil

          storage.hmset "#{self.name}.handset_capabilities", *capabilities_to_group.each_with_object([]) { |o, a| a << o }.flatten
          storage.keys("#{Handset.name}*").sort.each_with_index { |n, i| storage.sadd HANDSET_KEY_NAME, n.split('.').last }

          storage.set(INITIALIZED_KEY_NAME, Time.now)

          lock_extender.kill
        end

        raise CacheError, 'error initializing cache!' unless valid?
      end

      def handsets
        @@handsets ||= Hash[*storage.smembers(HANDSET_KEY_NAME).collect { |n| [n, Handset.new(n)] }.flatten]
      end

      def handset_capabilities
        @@handset_capabilities ||= storage.hgetall("#{self.name}.handset_capabilities")
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
