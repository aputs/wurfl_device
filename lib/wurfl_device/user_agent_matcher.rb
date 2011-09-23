
module WurflDevice
  class UserAgentMatcher
    class << self
      def match(user_agent)
        return nil unless Device.initialized?

        #user_agent = "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320)"
        #user_agent = "BlackBerry9650/5.0.0.732 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/105"
        #user_agent = "Mozilla/5.0 (BlackBerry; U; BlackBerry 9800; en-US) AppleWebKit/534.1+ (KHTML, like Gecko) Version/6.0.0.246 Mobile Safari/534.1+"
        #user_agent = "BlackBerry8330/4.3.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 VendorID/105"
        #user_agent = "Cricket-A200/1.0 UP.Browser/6.3.0.7 (GUI) MMP/2.0"
        #user_agent = "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Nexus One Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
        #user_agent = "SonyEricssonK700i/R2AC SEMC-Browser/4.0.2 Profile/MIDP-2.0 Configuration/CLDC-1.1"
        #user_agent = "SonyEricssonK600i/R2T Browser/SEMC-Browser/4.2 Profile/MIDP-2.0 Configuration/CLDC-1.1"
        #user_agent = "NokiaN90-1/3.0541.5.2 Series60/2.8 Profile/MIDP-2.0 Configuration/CLDC-1.1"

        # exact match
        device_id = WurflDevice.db.hget("wurfl:user_agents", user_agent)
        return device_id if device_id

        # ld match
        user_agents = WurflDevice.db.zrangebyscore("wurfl:user_agents_sorted", user_agent.length, user_agent.length)
        matched_user_agents = Hash.new
        user_agents.each { |ua| matched_user_agents[ua] = levenshtein_distance(clean_user_agent(user_agent), clean_user_agent(ua)) }
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

      # compute levenshtein_distance between two string
      def levenshtein_distance(str1, str2)
        s = str1
        t = str2
        n = s.length
        m = t.length
        max = n/2

        return m if (0 == n)
        return n if (0 == m)
        return n if (n - m).abs > max

        d = (0..m).to_a
        x = nil

        n.times do |i|
          e = i+1

          m.times do |j|
            cost = (s[i] == t[j]) ? 0 : 1
            x = [
                 d[j+1] + 1, # insertion
                 e + 1,      # deletion
                 d[j] + cost # substitution
                ].min
            d[j] = e
            e = x
          end

          d[m] = x
        end

        return x
      end      
    end
  end
end
