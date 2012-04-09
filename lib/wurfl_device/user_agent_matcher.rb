# encoding: utf-8
require 'text'

module WurflDevice
  class UserAgentMatcher
    attr_reader :user_agent, :user_agent_brand, :user_agent_matcher_list

    def initialize(user_agent_string="")
      @user_agent = UserAgent.new(user_agent_string)
      @user_agent_brand = @user_agent.classify
      @user_agent_matcher_list = Cache.user_agent_matchers(@user_agent_brand).keys
    end

    def self.match(ua, cache_check=true)
      # exact match
      return Cache.user_agents[ua] if Cache.user_agents[ua]

      # in user agent matched cache
      return Cache.user_agent_cached(ua) if cache_check && Cache.user_agent_cached(ua)

      # try brand matchers
      matcher = self.new(ua)
      matched_ua = matcher.send("matcher_#{matcher.user_agent_brand}") #rescue nil
      unless matched_ua
        if matcher.user_agent =~ /^Mozilla/i
          matched_ua = matcher.ld_match(5)
        else
          matched_ua = matcher.ris_match(matcher.user_agent.first_slash)
        end
      end

      matched_ua = matcher.send(:last_attempts) unless matched_ua

      return Cache.user_agents[matched_ua]
    end

    def ris_match(tolerance=nil)
      tolerance = WurflDevice.config.worst_match if tolerance.nil?
      ua_string = user_agent.dup
      curlen = ua_string.length
      while curlen >= tolerance
        user_agent_matcher_list.map do |ua|
          next if ua.length < curlen
          if ua.index(ua_string) == 0
            return ua
          end
        end
        ua_string = ua_string.slice(0, curlen-1)
        curlen = ua_string.length
      end
      return nil
    end

    def ld_match(tolerance=nil)
      tolerance = WurflDevice.config.worst_match if tolerance.nil?
      length = user_agent.length
      best = tolerance
      current = 0
      match = nil
      user_agent_matcher_list.map do |ua|
        next unless ua.length.between?(length - tolerance, length + tolerance)
        current = Text::Levenshtein.distance(ua, user_agent)
        if current <= best
          best = current
          match = ua
        end
      end
      return match
    end

  protected
    # user agent matchers
    def last_attempts
      return case
      # OpenWave
      when user_agent.contains('UP.Browser/7.2')
        'DO_NOT_MATCH_UP.Browser/7.2'
      when user_agent.contains('UP.Browser/7')
        'DO_NOT_MATCH_UP.Browser/7'
      when user_agent.contains('UP.Browser/6.2')
        'DO_NOT_MATCH_UP.Browser/6.2'
      when user_agent.contains('UP.Browser/6')
        'DO_NOT_MATCH_UP.Browser/6'
      when user_agent.contains('UP.Browser/5')
        'UP.Browser/5'
      when user_agent.contains('UP.Browser/4')
        'DO_NOT_MATCH_UP.Browser/4'
      when user_agent.contains('UP.Browser/3')
        'DO_NOT_MATCH_UP.Browser/4'
      # Series 60
      when user_agent.contains('Series60')
        'DO_NOT_MATCH_NOKIA_SERIES60'
      when user_agent.contains('Series80')
        'DO_NOT_MATCH_NOKIA_SERIES80'
      # Access/Net Front
      when user_agent.contains(['NetFront/3.0', 'ACS-NF/3.0'])
        'DO_NOT_MATCH_NETFRONT_3'
      when user_agent.contains(['NetFront/3.1', 'ACS-NF/3.1'])
        'DO_NOT_MATCH_NETFRONT_3_1'
      when user_agent.contains(['NetFront/3.2', 'ACS-NF/3.2'])
        'DO_NOT_MATCH_NETFRONT_3_2'
      when user_agent.contains(['NetFront/3.3', 'ACS-NF/3.3'])
        'DO_NOT_MATCH_NETFRONT_3_3'
      when user_agent.contains('NetFront/3.4')
        'DO_NOT_MATCH_NETFRONT_3_5'
      when user_agent.contains('NetFront/3.5')
        'DO_NOT_MATCH_NETFRONT_3_5'
      # Contains Mozilla/, but not at the beginning of the UA
      when !user_agent.starts_with('Mozilla/') && user_agent.contains('Mozilla/')
        'DO_NOT_MATCH_MOZILLA'
      # Obigo
      when user_agent.contains(['ObigoInternetBrowser/Q03C', 'AU-MIC/2', 'AU-MIC-', 'AU-OBIGO', 'Obigo/Q03', 'Obigo/Q04', 'ObigoInternetBrowser/2', 'Teleca Q03B1'])
        'DO_NOT_MATCH_MOZILLA'
      # DoCoMo
      when user_agent.starts_with('DoCoMo') || user_agent.starts_with('KDDI')
        'DO_NOT_MATCH_DOCOMO_GENERIC_JAP_1'
      # Generic Mozilla
      when user_agent.contains(['Mozilla/4.0', 'Mozilla/5.0', 'Mozilla/6.0'])
        'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
      else
        WurflDevice::GENERIC
      end
    end

    # mobile user agents
    def matcher_nokia
      return ris_match(user_agent.index_of_or_length(['/', ' '], user_agent.index('Nokia')))
    end

    def matcher_samsung
      matched_ua = case
      when user_agent.starts_with('SAMSUNG') || user_agent.starts_with('SEC-') || user_agent.starts_with('SCH-')
        ris_match_ua_first_slash
      when user_agent.starts_with('Samsung') || user_agent.starts_with('SPH') || user_agent.starts_with('SGH')
        ris_match(user_agent.first_space)
      else
        ris_match(user_agent.second_slash)
      end

      return matched_ua if matched_ua

      return case
      when user_agent.starts_with('SAMSUNG')
        ld_match(8)
      else
        ris_match(user_agent.index_of_or_length('/', user_agent.index('Samsung')))
      end
    end

    def matcher_blackberry
      matched_ua = case
      when user_agent.starts_with('BlackBerry')
        ris_match(user_agent.ordinal_index_of(';', 3))
      else
        ris_match_ua_first_slash
      end

      return matched_ua if matched_ua

      if user_agent =~ /Black[Bb]erry[^\/\s]+\/(\d\.\d)/
        vercode = $1
        {
          '2.'  => 'DO_NOT_MATCH_BLACKBERRY_2',
          '3.2' => 'DO_NOT_MATCH_BLACKBERRY_3_2',
          '3.3' => 'DO_NOT_MATCH_BLACKBERRY_3_3',
          '3.5' => 'DO_NOT_MATCH_BLACKBERRY_3_5',
          '3.6' => 'DO_NOT_MATCH_BLACKBERRY_3_6',
          '3.7' => 'DO_NOT_MATCH_BLACKBERRY_3_7',
          '4.1' => 'DO_NOT_MATCH_BLACKBERRY_4_1',
          '4.2' => 'DO_NOT_MATCH_BLACKBERRY_4_2',
          '4.3' => 'DO_NOT_MATCH_BLACKBERRY_4_3',
          '4.5' => 'DO_NOT_MATCH_BLACKBERRY_4_5',
          '4.6' => 'DO_NOT_MATCH_BLACKBERRY_4_6',
          '4.7' => 'DO_NOT_MATCH_BLACKBERRY_4_7',
          '4.'  => 'DO_NOT_MATCH_BLACKBERRY_4',
          '5.'  => 'DO_NOT_MATCH_BLACKBERRY_5',
          '6.'  => 'DO_NOT_MATCH_BLACKBERRY_6',
        }.each_pair { |vercode, device_ua| return device_ua if vercode.index(vercode) }
      end
    end

    def matcher_sonyericsson
      matched_ua = case
      when user_agent.starts_with('SonyEricsson')
        ris_match(user_agent.first_slash - 1)
      else
        ris_match(user_agent.second_slash)
      end
      return matched_ua if matched_ua
      return ris_match(14) 
    end

    def matcher_motorola
      tolerance = 5
      matched_ua = case
      when user_agent.starts_with('Mot-') || user_agent.starts_with('MOT-') || user_agent.starts_with('Motorola')
        ris_match(5)
      else
        ld_match(5)
      end
      return matched_ua if matched_ua
      return 'DO_NOT_MATCH_MIB_2_2' if user_agent.contains('MIB/2.2') || user_agent.contains('MIB/BER2.2')
    end

    def matcher_alcatel
      ris_match_ua_first_slash
    end

    def matcher_apple
      tolerance = 0
      matched_ua = case
      when user_agent.starts_with('Apple')
        tolerance = user_agent.ordinal_index_of(' ', 3)
        tolerance = user_agent.length if tolerance == -1
        ris_match(tolerance)
      else
        ris_match(user_agent.ordinal_index_of(';', 0))
      end
      return matched_ua if matched_ua
      return case
      when user_agent.contains('iPod')
        'Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/3A100a Safari/419.3'
      when user_agent.contains('iPad')
        'Mozilla/5.0 (iPad; U; CPU iPhone OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7D11'
      when user_agent.contains('iPhone')
        'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A538a Safari/419.3'
      else
        WurflDevice::GENERIC
      end
    end

    def matcher_benq
      ris_match_ua_first_slash
    end

    def matcher_docomo
      matched_ua = case
      when user_agent.num_slashes >= 2
        ris_match(user_agent.second_slash)
      else
        ris_match(user_agent.first_open_paren)
      end
      return matched_ua if matched_ua
      return case
      when user_agent[7] == '2'
        'DO_NOT_MATCH_DOCOMO_GENERIC_JAP_2'
      else
        'DO_NOT_MATCH_DOCOMO_GENERIC_JAP_1'
      end
    end

    def matcher_grundig
      ris_match_ua_first_slash
    end

    def matcher_htc
      matched_ua = ris_match_ua_first_slash
      return matched_ua if matched_ua
      return ris_match(6)
    end

    def matcher_kddi
      matched_ua = case
      when user_agent.starts_with('KDDI/')
        ris_match(user_agent.second_slash)
      else
        ris_match_ua_first_slash
      end
      return matched_ua if matched_ua
      return 'DO_NOT_MATCH_UP.Browser/6.2'
    end

    def matcher_kyocera
      ris_match_ua_first_slash
    end

    def matcher_lg
      matched_ua = ris_match(user_agent.index_of_or_length('/', user_agent.index('LG')))
      return matched_ua if matched_ua
      return ris_match(7)
    end

    def matcher_mitsubishi
      ris_match_ua_first_slash
    end

    def matcher_nec
      matched_ua = ris_match_ua_first_slash
      return matched_ua if matched_ua
      return ris_match(2)
    end

    def matcher_nintendo
      matched_ua = ld_match(user_agent.first_slash)
      return matched_ua if matched_ua
      return case
      when user_agent.contains('Nintendo Wii')
        'Opera/9.00 (Nintendo Wii; U; ; 1621; en)'
      when user_agent.contains('Nintendo DSi')
        'Opera/9.50 (Nintendo DSi; Opera/483; U; en-US)'
      when user_agent.starts_with('Mozilla/') && user_agent.contains('Nitro') && user_agent.contains('Opera')
        'Mozilla/4.0 (compatible; MSIE 6.0; Nitro) Opera 8.50 [en]'
      else
        'Opera/9.00 (Nintendo Wii; U; ; 1621; en)'
      end
    end

    def matcher_panasonic
      ris_match_ua_first_slash
    end

    def matcher_pantech
      return ris_match_ua_first_slash unless user_agent.starts_with('Pantech')
      return ris_match(5)
    end

    def matcher_philips
      ris_match_ua_first_slash
    end

    def matcher_portalmmm
      WurflDevice::GENERIC
    end

    def matcher_qtek
      ris_match_ua_first_slash
    end

    def matcher_sagem
      ris_match_ua_first_slash
    end

    def matcher_sharp
      ris_match_ua_first_slash
    end

    def matcher_siemens
      ris_match_ua_first_slash
    end

    def matcher_spv
      pos = user_agent.index(';')
      tolerance = pos || user_agent.index('SPV')
      return ris_match(tolerance)
    end

    def matcher_toshiba
      ris_match_ua_first_slash
    end

    def matcher_vodafone
      matched_ua = ris_match_ua_first_slash
      return matched_ua if matched_ua
      return ld_match(user_agent)
    end

    def matcher_android
      return case
      when user_agent.contains('Froyo')
        'DO_NOT_MATCH_ANDROID_2_2'
      when user_agent =~ /#Android[\s\/](\d).(\d)#/
        version = "generic_android_ver#{$1}_#{$2}"
        version = 'generic_android_ver2' if version == 'generic_android_ver2_0'
        android_uas = {
          'generic_android_ver1_5'  => 'DO_NOT_MATCH_ANDROID_1_5',
          'generic_android_ver1_6'  => 'DO_NOT_MATCH_GENERIC_ANDROID_1_6',
          'generic_android_ver2'    => 'DO_NOT_MATCH_GENERIC_ANDROID_2_0',
          'generic_android_ver2_1'  => 'DO_NOT_MATCH_GENERIC_ANDROID_2_1',
          'generic_android_ver2_2'  => 'DO_NOT_MATCH_ANDROID_2_2',
        }
        if android_uas.has_key?(version)
          android_uas[version]
        else
          'DO_NOT_MATCH_GENERIC_ANDROID'
        end
      else
        'DO_NOT_MATCH_GENERIC_ANDROID'
      end
    end

    # mobile browsers
    def matcher_operamini
      matched_ua = ris_match_ua_first_slash
      return matched_ua if matched_ua
      return case
      when user_agent =~ /#Opera Mini\/([1-5])#/
        "DO_NOT_MATCH_BROWSER_OPERA_MINI_#{$1}_0"
      when user_agent.contains('Opera Mobi')
        'DO_NOT_MATCH_GENERIC_OPERA_MINI_VERSION_4'
      else
        'DO_NOT_MATCH_GENERIC_OPERA_MINI_VERSION_1'
      end
    end

    def matcher_windowsce
      matched_ua = ld_match(5)
      return matched_ua if matched_ua
      return 'DO_NOT_MATCH_REMOVE_GENERIC_MS_MOBILE_BROWSER_VER1'
    end

    # robots
    def matcher_bot
      matched_ua = ris_match_ua_first_slash
      return matched_ua if matched_ua
      return 'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
    end

    # desktop browsers
    def matcher_msie
      if user_agent =~ /^Mozilla\/4\.0 \(compatible; MSIE (\d)\.(\d);/
        version = $1.to_i
        version_sub = $2.to_i
        return case
        when version == 7
          'Mozilla/4.0 (compatible; MSIE 7.0;'
        when version == 8
          'Mozilla/4.0 (compatible; MSIE 8.0;'
        when version == 6
          'Mozilla/4.0 (compatible; MSIE 6.0;'
        when version == 4
          'Mozilla/4.0 (compatible; MSIE 4.0;'
        when version == 5
          version_sub == 5 ? 'Mozilla/4.0 (compatible; MSIE 5.5;' : 'Mozilla/4.0 (compatible; MSIE 5.0;'
        else
          'msie'
        end
      else
        user_agent.sub!(/( \.NET CLR [\d\.]+;?| Media Center PC [\d\.]+;?| OfficeLive[a-zA-Z0-9\.\d]+;?| InfoPath[\.\d]+;?)/, '')
        matched_ua = ris_match_ua_first_slash
        return matched_ua if matched_ua
      end

      return case
      when user_agent.contains(['SLCC1', 'Media Center PC', '.NET CLR', 'OfficeLiveConnector'])
        'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
      else
        WurflDevice::GENERIC
      end
    end

    def matcher_firefox
      return case
      when user_agent =~ /Firefox\/(\d)\.(\d)/
        version = $1.to_i
        version_sub = $2.to_i
        matched_ua = case
        when version == 3
          version_sub == 5 ? 'Firefox/3.5' : 'Firefox/3.0'
        when version == 2
          'firefox_2'
        when version == 1
          version_sub == 5 ? 'Firefox/1.5' : 'Firefox/1.0'
        else
          nil
        end
      else
        matched_ua = ld_match(5)
      end
    end

    def matcher_chrome
      matched_ua = ris_match(user_agent.index_of_or_length('/', user_agent.index('Chrome')))
      return matched_ua if matched_ua
      return 'Chrome'
    end

    def matcher_konqueror
      ris_match_ua_first_slash
    end

    def matcher_opera
      matched_ua = case
      when user_agent.contains('Opera/10')
        'Opera/10'
      when user_agent.contains('Opera/9')
        'Opera/9'
      when user_agent.contains('Opera/8')
        'Opera/8'
      when user_agent.contains('Opera/7')
        'Opera/7'
      else
        nil
      end
      return matched_ua if matched_ua
      matched_ua = ld_match(5)
      matched_ua = 'Opera' unless matched_ua
      return matched_ua
    end

    def matcher_safari
      matched_ua = ris_match_ua_first_slash
      return matched_ua if matched_ua
      return case
      when user_agent.contains('Macintosh') || user_agent.contains('Windows')
        'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
      else
        WurflDevice::GENERIC
      end
    end

    def matcher_aol
      'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
    end

    def matcher_catchall
      matched_ua = ris_match(5)
      matched_ua = ld_match(5) unless matched_ua
      return matched_ua
    end

    def ris_match_ua_first_slash
      ris_match(user_agent.first_slash)
    end
  end
end
