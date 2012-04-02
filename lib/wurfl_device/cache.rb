require 'redis'
require 'redis/lock'
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
        storage.lock_for(LOCKED_KEY_NAME, DB_LOCK_EXPIRES, DB_LOCK_TIMEOUT) do |lock|
          storage.del(INITIALIZED_KEY_NAME)

          @@handsets = nil
          storage.keys("#{self.name.split('::').first}*").each { |n| storage.del n }

          lock_extender = Thread.new {
            loop {
              sleep(DB_LOCK_EXPIRES * 0.90)
              lock.extend_lock(LOCKED_KEY_NAME, DB_LOCK_EXPIRES)
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
    end
  end
end
