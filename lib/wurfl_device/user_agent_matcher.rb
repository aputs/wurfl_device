require 'text'

module WurflDevice
  class UserAgentMatcher
    class << self
      def match(user_agent)
        return nil unless WurflDevice.initialized?

        # exact match
        device_id = WurflDevice.db.hget("wurfl:user_agents", user_agent)
        return device_id if device_id

        # ld match
        user_agents = WurflDevice.db.zrangebyscore("wurfl:user_agents_sorted", user_agent.length, user_agent.length)
        matched_user_agents = Hash.new
        cleaned_user_agent = clean_user_agent(user_agent)
        user_agents.each { |ua| matched_user_agents[ua] = Text::Levenshtein.distance(cleaned_user_agent, clean_user_agent(ua)) }
        user_agent_first_slash = user_agent.slice(0, first_slash(user_agent))
        matched_user_agents.each_pair do |k, v|
          if user_agent_first_slash.casecmp(k.slice(0, first_slash(k))) == 0
            matched_user_agents[k] = matched_user_agents[k] - 0.5
          end
        end
        matched_ua = matched_user_agents.sort { |a, b| a[1]<=>b[1] }.flatten[0]
        device_id = WurflDevice.db.hget("wurfl:user_agents", matched_ua)
        return device_id if device_id

        # last attempts
        return 'opwv_v7_generic' if user_agent.index('UP.Browser/7')
        return 'opwv_v6_generic' if user_agent.index('UP.Browser/6')
        return 'upgui_generic' if user_agent.index('UP.Browser/5')
        return 'uptext_generic' if user_agent.index('UP.Browser/4')
        return 'uptext_generic' if user_agent.index('UP.Browser/3')
        return 'nokia_generic_series60' if user_agent.index('Series60')
        return 'generic_web_browser' if user_agent.index('Mozilla/4.0')
        return 'generic_web_browser' if user_agent.index('Mozilla/5.0')
        return 'generic_web_browser' if user_agent.index('Mozilla/6.0')

        return WurflDevice::GENERIC
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

      def clean_user_agent(user_agent)
        user_agent = removeUPLinkFromUA(user_agent)

        # remove serial numbers
        user_agent = user_agent.sub(/\/SN\d{15}/, '/SNXXXXXXXXXXXXXXX')
        user_agent = user_agent.sub(/\[(ST|TF|NT)\d+\]/, '')

        # remove locale identifiers
        user_agent = user_agent.sub(/([ ;])[a-zA-Z]{2}-[a-zA-Z]{2}([ ;\)])/, '\1xx-xx\2')

        user_agent = normalizeBlackberry(user_agent)
        user_agent = normalizeAndroid(user_agent)

        return user_agent.strip
      end

      def removeUPLinkFromUA(user_agent)
        pos = user_agent.index('UP.Link')
        return user_agent unless pos
        return user_agent.slice(0..(pos-1))
      end

      def normalizeBlackberry(user_agent)
        pos = user_agent.index('BlackBerry')
        return user_agent if pos.nil?
        return user_agent.slice(pos, user_agent.length - pos)
      end

      def normalizeAndroid(user_agent)
        return user_agent.sub(/(Android \d\.\d)([^; \/\)]+)/, '\1')
      end
    end
  end
end
