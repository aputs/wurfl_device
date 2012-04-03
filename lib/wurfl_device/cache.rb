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

          doc = ::LibXML::XML::Document.file(filename)
          doc.find('//devices/device').each do |p|
            d_info = p.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
            next if d_info['id'].empty?
            handset = Handset.new d_info['id']
            handset.capabilities['user_agent'] = d_info['user_agent']
            handset.capabilities['fall_back_id'] = d_info['fall_back']
            p.each_element do |g|
              g_info = g.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
              c_group = Capability::Group.new
              g.each_element do |c|
                c_info = c.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
                c_group[c_info['name']] = c_info['value']
              end
              handset.capabilities[g_info['id']] = c_group
            end
            handset.store_to_cache
          end

          lock_extender.exit

          storage.keys("#{Handset.name}*").each_with_index { |n, i| storage.sadd HANDSET_KEY_NAME, n.split('.').last }
          storage.set(INITIALIZED_KEY_NAME, Time.now)
        end

        raise CacheError, 'error initializing cache!' unless valid?
      end

      def handsets
        @@handsets ||= Hash[*storage.smembers(HANDSET_KEY_NAME).collect { |n| [n, Handset.new(n)] }.flatten]
      end

      def lock_for(key, expires=60, timeout=10)
        if lock(key, expires, timeout)
          response = yield(self) if block_given?
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
