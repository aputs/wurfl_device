require 'etc'
require 'redis'

require 'wurfl_device/version'

module WurflDevice
  autoload :Capability,         'wurfl_device/capability'
  autoload :Constants,          'wurfl_device/constants'
  autoload :Device,             'wurfl_device/device'
  autoload :Handset,            'wurfl_device/handset'
  autoload :UI,                 'wurfl_device/ui'
  autoload :CLI,                'wurfl_device/cli'
  autoload :UserAgent,          'wurfl_device/user_agent'
  autoload :UserAgentMatcher,   'wurfl_device/user_agent_matcher'
  autoload :XmlLoader,          'wurfl_device/xml_loader'

  class WurflDeviceError < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end

  class CacheError    < WurflDeviceError; status_code(10); end

  class << self
    attr_writer :ui, :db

    def ui
      @ui ||= UI.new
    end

    def db
      @db ||= Redis.new(:db => Constants::DB_INDEX)
    end

    def tmp_dir
      File.join(Etc.systmpdir, 'wurfl_device')
    end

    def get_actual_device(device_id)
      capabilities = Capability.new
      actual_device = get_actual_device_raw(device_id)
      return nil if actual_device.nil?
      actual_device.each_pair do |key, value|
        if key =~ /^(.+)\:(.+)$/i
          capabilities[$1] ||= Capability.new
          capabilities[$1][$2] = parse_string_value(value)
        else
          capabilities[key] = parse_string_value(value)
        end
      end
      capabilities
    end

    def get_device_from_id(device_id)
      device = Device.new(device_id)
      return device if device.is_valid?
      return nil
    end

    def get_device_from_ua(user_agent)
      matcher = UserAgentMatcher.new.match(user_agent)
      return matcher.device
    end

    def get_device_from_ua_cache(user_agent, bypass_main_cache=false)
      unless bypass_main_cache
        cached_device = db.hget(Constants::WURFL_USER_AGENTS_CACHED, user_agent)
        return Marshal::load(cached_device) unless cached_device.nil?
      end
      cached_device = db.hget(Constants::WURFL_USER_AGENTS, user_agent)
      return Marshal::load(cached_device) unless cached_device.nil?
      return nil
    end

    def save_device_in_ua_cache(user_agent, device)
      db.hset(Constants::WURFL_USER_AGENTS_CACHED, user_agent, Marshal::dump(device))
    end

    def get_info
      db.hgetall(Constants::WURFL_INFO)
    end

    # cache related
    def clear_user_agent_cache
      db.del(Constants::WURFL_USER_AGENTS_CACHED)
    end

    def clear_cache
      db.keys("#{Constants::WURFL}*").each { |k| db.del k }
    end

    def clear_devices
      db.keys("#{Constants::WURFL_DEVICES}*").each { |k| db.del k }
      db.del(Constants::WURFL_INITIALIZED)
      db.del(Constants::WURFL_INFO)
    end

    def get_user_agents
      db.hkeys(Constants::WURFL_USER_AGENTS)
    end

    def get_user_agents_in_cache
      db.hkeys(Constants::WURFL_USER_AGENTS_CACHED)
    end

    def get_user_agents_in_index(matcher)
      db.hkeys("#{Constants::WURFL_DEVICES_INDEX}#{matcher}")
    end

    def get_actual_device_raw(device_id)
      db.hgetall("#{Constants::WURFL_DEVICES}#{device_id}")
    end

    def get_devices
      db.keys("#{Constants::WURFL_DEVICES}*")
    end

    def get_indexes
      db.keys("#{Constants::WURFL_DEVICES_INDEX}*")
    end

    def rebuild_user_agent_cache
      # update the cache's
      db.del(Constants::WURFL_USER_AGENTS)
      get_indexes.each { |k| db.del(k) }

      get_devices.each do |device_id|
        device_id.gsub!(Constants::WURFL_DEVICES, '')
        actual_device = get_actual_device(device_id)
        next if actual_device.nil?
        user_agent = actual_device.user_agent
        next if user_agent.nil? || user_agent.empty?
        device = Device.new(device_id)
        next unless device.is_valid?
        db.hset(Constants::WURFL_USER_AGENTS, user_agent, Marshal::dump(device))

        next if user_agent =~ /^DO_NOT_MATCH/i
        matcher = UserAgentMatcher.new.get_index(user_agent)
        db.hset("#{Constants::WURFL_DEVICES_INDEX}#{matcher}", user_agent, device_id)
      end

      get_user_agents_in_cache.each do |user_agent|
        db.hdel(Constants::WURFL_USER_AGENTS_CACHED, user_agent)
        UserAgentMatcher.new.match(user_agent)
      end
    end

    def is_initialized?
      status = parse_string_value(db.get(Constants::WURFL_INITIALIZED))
      return false if status.nil?
      return false unless status.is_a?(TrueClass)
      true
    end

    def initialize_cache
      # make sure only process can initialize at a time
      # don't initialize if there is another initializing
      lock_the_cache_for_initializing do
        db.set(Constants::WURFL_INITIALIZED, false)

        # download & parse the wurfl xml
        xml_list = Array.new
        xml_list << download_wurfl_xml_file
        xml_list << download_wurfl_web_patch_xml_file

        xml_list.each do |xml_file|
          (devices, version, last_updated) = XmlLoader.load_xml_file(xml_file) do |capabilities|
            device_id = capabilities.delete('id')
            next if device_id.nil? || device_id.empty?
            db.del("#{Constants::WURFL_DEVICES}#{device_id}")
            user_agent = capabilities.delete('user_agent')
            fall_back = capabilities.delete('fall_back')

            device_id.strip! unless device_id.nil?
            user_agent.strip! unless user_agent.nil?
            fall_back.strip! unless fall_back.nil?

            db.hset("#{Constants::WURFL_DEVICES}#{device_id}", "id", device_id)
            db.hset("#{Constants::WURFL_DEVICES}#{device_id}", "user_agent", user_agent)
            db.hset("#{Constants::WURFL_DEVICES}#{device_id}", "fall_back", fall_back)

            capabilities.each_pair do |key, value|
              if value.is_a?(Hash)
                value.each_pair do |k, v|
                  db.hset("#{Constants::WURFL_DEVICES}#{device_id}", "#{key.to_s}:#{k.to_s}", v)
                end
              else
                db.hset("#{Constants::WURFL_DEVICES}#{device_id}", "#{key.to_s}", value)
              end
            end
          end

          next if version.nil?
          db.set(Constants::WURFL_INITIALIZED, true)
          db.hset(Constants::WURFL_INFO, "version", version)
          db.hset(Constants::WURFL_INFO, "last_updated", Time.now)
        end
      end
    end

    def parse_string_value(value)
      return value unless value.is_a?(String)
      # convert to utf-8 (wurfl.xml encoding format)
      value.force_encoding('UTF-8')
      return false if value =~ /^false/i
      return true if value =~ /^true/i
      return value.to_i if (value == value.to_i.to_s)
      return value.to_f if (value == value.to_f.to_s)
      value
    end
  protected
    def download_wurfl_xml_file
      wurfl_xml_source = "http://sourceforge.net/projects/wurfl/files/WURFL/2.2/wurfl-2.2.xml.gz"
      FileUtils.mkdir_p(WurflDevice.tmp_dir)
      FileUtils.cd(WurflDevice.tmp_dir)
      `wget --timeout=60 -qN -- #{wurfl_xml_source} > /dev/null`
      raise "Failed to download wurfl-latest.xml.gz" unless $? == 0

      wurfl_xml_filename = File.basename(wurfl_xml_source)
      `gunzip -qc #{wurfl_xml_filename} > wurfl.xml`
      raise 'Failed to unzip wurfl-latest.xml.gz' unless $? == 0

      wurfl_xml_file_extracted = File.join(WurflDevice.tmp_dir, 'wurfl.xml')
      raise "wurfl.xml does not exists!" unless File.exists?(wurfl_xml_file_extracted)

      wurfl_xml_file_extracted
    end

    def download_wurfl_web_patch_xml_file
      wurfl_web_patch_xml_source = 'http://sourceforge.net/projects/wurfl/files/WURFL/2.2/web_browsers_patch.xml'
      `wget --timeout=60 -qN -- #{wurfl_web_patch_xml_source} > /dev/null`
      raise "Failed to download wurfl-latest.xml.gz" unless $? == 0

      wurfl_web_patch_xml = File.join(WurflDevice.tmp_dir, 'web_browsers_patch.xml')
      raise "web_browsers_patch.xml does not exists!" unless File.exists?(wurfl_web_patch_xml)

      wurfl_web_patch_xml
    end

    def lock_the_cache_for_initializing
      start_at = Time.now
      success = false
      while Time.now - start_at < Constants::LOCK_TIMEOUT
        success = true and break if try_lock
        sleep Constants::LOCK_SLEEP
      end
      if block_given? and success
        yield
        unlock
      end
    end

    def try_lock
      now = Time.now.to_f
      @expires_at = now + Constants::LOCK_EXPIRE
      return true if db.setnx(Constants::WURFL_INITIALIZING, @expires_at)
      return false if db.get(Constants::WURFL_INITIALIZING).to_f > now
      return true if db.getset(Constants::WURFL_INITIALIZING, @expires_at).to_f <= now
      return false
    end

    def unlock(force=false)
      db.del(Constants::WURFL_INITIALIZING) if db.get(Constants::WURFL_INITIALIZING).to_f == @expires_at or force
    end
  end
end
