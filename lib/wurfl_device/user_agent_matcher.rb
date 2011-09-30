require 'text'

module WurflDevice
  class UserAgentMatcher
    attr_accessor :user_agent, :user_agent_cleaned, :device

    def match(user_agent)
      raise CacheError, "wurfl cache is not initialized" unless WurflDevice.is_initialized?

      lookup_time = 0.0
      @matcher_history = Array.new
      @info = Capability.new
      @user_agent = user_agent
      @user_agent_cleaned = UserAgentMatcher.clean_user_agent(user_agent)
      @device = nil

      # exact match
      @device = WurflDevice.get_device_from_ua_cache(@user_agent)
      @device = WurflDevice.get_device_from_ua_cache(@user_agent_cleaned) if @device.nil?

      # already in cache so return immediately
      return self if !@device.nil? && @device.is_valid?

      # ris match
      if @device.nil?
        user_agent = @user_agent
        user_agent_list = WurflDevice.get_user_agents_in_index(UserAgentMatcher.get_index(user_agent)).sort { |a, b| a[0] <=> b[0] }
        tolerance = UserAgentMatcher.first_slash(user_agent)-1
        curlen = user_agent.length
        while curlen >= tolerance
          user_agent_list.map do |ua, device_id|
            if ua.index(user_agent) == 0
              @device = Device.new(device_id)
              break
            end
          end
          break unless @device.nil?
          user_agent = user_agent.slice(0, curlen-1)
          curlen = user_agent.length
        end
      end

      # last attempts
      if @device.nil?
        user_agent = @user_agent
        device_id = WurflDevice::Constants::GENERIC
        device_id = 'opwv_v7_generic' if user_agent.index('UP.Browser/7')
        device_id = 'opwv_v6_generic' if user_agent.index('UP.Browser/6')
        device_id = 'upgui_generic' if user_agent.index('UP.Browser/5')
        device_id = 'uptext_generic' if user_agent.index('UP.Browser/4')
        device_id = 'uptext_generic' if user_agent.index('UP.Browser/3')
        device_id = 'nokia_generic_series60' if user_agent.index('Series60')
        device_id = 'generic_web_browser' if user_agent.index('Mozilla/4.0')
        device_id = 'generic_web_browser' if user_agent.index('Mozilla/5.0')
        device_id = 'generic_web_browser' if user_agent.index('Mozilla/6.0')
        @device = WurflDevice.get_device_from_id(device_id)
      end

      WurflDevice.save_device_in_ua_cache(@user_agent, @device)

      return self
    end

    class << self
      def get_index(user_agent)
        # create device index
        matcher = 'Generic'
        WurflDevice::Constants::USER_AGENT_MATCHERS.each do |m|
          if Regexp.new(m, Regexp::IGNORECASE) =~ user_agent
            matcher = m
            break
          end
        end
        return matcher
      end

      def clean_user_agent(user_agent)
        user_agent = remove_up_link_from_ua(user_agent)

        # remove nokia-msisdn header
        user_agent = remove_nokia_msisdn(user_agent)

        # clean up myphone id's
        user_agent = user_agent.sub("'M', 'Y' 'P', 'H', 'O', 'N', 'E'", "MyPhone")
        
        # remove serial numbers
        user_agent = user_agent.sub(/\/SN\d{15}/, '/SNXXXXXXXXXXXXXXX')
        user_agent = user_agent.sub(/\[(ST|TF|NT)\d+\]/, '')

        # remove locale identifiers
        user_agent = user_agent.sub(/([ ;])[a-zA-Z]{2}-[a-zA-Z]{2}([ ;\)])/, '\1xx-xx\2')

        user_agent = normalize_blackberry(user_agent)
        user_agent = normalize_android(user_agent)

        return user_agent.strip
      end

      def first_slash(user_agent)
        pos = user_agent.index('/')
        return user_agent.length if pos.nil?
        return pos
      end

      def second_slash(user_agent)
        first = user_agent.index('/')
        return user_agent.length if first.nil?
        first = first + 1
        second = user_agent.index('/', first)
        return user_agent.length if second.nil?
        return second
      end

      def first_space(user_agent)
        pos = user_agent.index(' ')
        return user_agent.length if pos.nil?
        return pos
      end

      def first_open_paren(user_agent)
        pos = user_agent.index('(')
        return user_agent.length if pos.nil?
        return pos
      end

      def remove_nokia_msisdn(user_agent)
        if user_agent =~ /^(.+)NOKIA-MSISDN\:\ (.+)$/i
          user_agent = $1
        end
        return user_agent
      end

      def remove_up_link_from_ua(user_agent)
        pos = user_agent.index('UP.Link')
        return user_agent unless pos
        return user_agent.slice(0..(pos-1))
      end

      def normalize_blackberry(user_agent)
        pos = user_agent.index('BlackBerry')
        return user_agent if pos.nil?
        return user_agent.slice(pos, user_agent.length - pos)
      end

      def normalize_android(user_agent)
        return user_agent.sub(/(Android \d\.\d)([^; \/\)]+)/, '\1')
      end

      def parse(user_agent)
        # grab all Agent/version strings as 'agents'
        agents = Array.new
        user_agent.split(/\s+/).each do |string| 
          if string =~ /\//
            agents << string
          end
        end
        return agents
      end
    end
  end
end
