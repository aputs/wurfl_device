require 'redis'
require 'redis/lock'
require 'libxml'

module WurflDevice
  module Cache
    DB_INDEX = 7
    DB_LOCK_TIMEOUT = 10
    DB_LOCK_EXPIRES = 60
    INITIALIZED_KEY_NAME = "#{self.name}.initialized"
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

          time_started = Time.now
          doc = ::LibXML::XML::Document.file(filename)
          doc.find('//devices/device').each do |p|
            d_info = p.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
            next if d_info['id'].empty?
            handset = Handset.new(d_info['id'], d_info['user_agent'], d_info['fall_back'])
            p.each_element do |g|
              g_info = g.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
              c_group = Capability::Group.new
              g.each_element do |c|
                c_info = c.attributes.each_with_object({}) { |a, h| h[a.name] = a.value }
                c_group[c_info['name']] = c_info['value']
              end
              handset.capabilities[g_info['id']] = c_group
            end
            if (Time.now - time_started) > DB_LOCK_EXPIRES
              lock.extend_lock(LOCKED_KEY_NAME, 60)
              time_started = Time.now
            end
            handset.store_to_cache
          end
          storage.set(INITIALIZED_KEY_NAME, Time.now)
        end
      end
    end
  end
end
