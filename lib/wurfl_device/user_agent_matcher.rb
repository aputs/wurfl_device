# encoding: utf-8
require 'text'

module WurflDevice
  class UserAgentMatcher
    attr_accessor :user_agent, :capabilities

    def match(user_agent)
      user_agent = UserAgent.new(user_agent) unless user_agent.kind_of?(UserAgent)

      @user_agent = user_agent.dup

      # exact match
      matched_data = Cache::UserAgentsMatched.get(@user_agent)
      unless matched_data.nil?
        @capabilities = Capability.new(MessagePack.unpack(matched_data.force_encoding('US-ASCII')))
        if !(@capabilities.nil? || @capabilities.empty?)
          return self
        end
      end

      matched_ua = nil
      matcher = "matcher_#{@user_agent.manufacturer.downcase}"
      if self.respond_to?(matcher)
        matched_ua = self.send(matcher, @user_agent)
      else
        if @user_agent =~ /^Mozilla/i
          tolerance = 5
          matched_ua = ld_match(@user_agent, tolerance)
        else
          tolerance = @user_agent.first_slash
          matched_ua = ris_match(@user_agent, tolerance)
        end
      end

      unless matched_ua.nil?
        device_id = Cache::UserAgents.get(matched_ua)
        device_id = Settings::GENERIC_XHTML if device_id.nil? || device_id.empty?
        @capabilities = Cache.build_capabilities(device_id)
      end

      if @capabilities.nil? || @capabilities.empty?
        device_id = Cache::UserAgents.get(last_attempts(@user_agent))
        device_id = Settings::GENERIC_XHTML if device_id.nil? || device_id.empty?
        @capabilities = Cache.build_capabilities(device_id)
      end

      if !(@capabilities.nil? || @capabilities.empty?)
        Cache::UserAgentsMatched.set @user_agent, MessagePack.pack(@capabilities)
      end

      return self
    end

    def ris_match(user_agent, tolerance=nil)
      tolerance = Settings::WORST_MATCH if tolerance.nil?
      device = nil
      user_agent_list = Cache::UserAgentsManufacturers.hkeys(user_agent.manufacturer).sort
      curlen = user_agent.length
      while curlen >= tolerance
        user_agent_list.each do |ua|
          next if ua.length < curlen
          if ua.index(user_agent) == 0
            return ua
          end
        end
        user_agent = user_agent.slice(0, curlen-1)
        curlen = user_agent.length
      end
      return nil
    end

    def ld_match(user_agent, tolerance=nil)
      tolerance = Settings::WORST_MATCH if tolerance.nil?
      user_agent_list = Cache::UserAgentsManufacturers.hkeys(user_agent.manufacturer).sort
      length = user_agent.length
      best = tolerance
      current = 0
      match = nil
      user_agent_list.each do |ua|
        next unless ua.length.between?(length - tolerance, length + tolerance)
        current = Text::Levenshtein.distance(ua, user_agent)
        if current <= best
          best = current
          match = ua
        end
      end
      return match unless match.nil?
      return nil
    end

  protected
    # user agent matchers
    def last_attempts(user_agent)
      device_ua = case
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
        Settings::GENERIC
      end

      return device_ua
    end

    # mobile user agents
    def matcher_nokia(user_agent)
      tolerance = user_agent.index_of_or_length(['/', ' '], user_agent.index('Nokia'))
      return ris_match(user_agent, tolerance)
    end

    def matcher_samsung(user_agent)
      tolerance = 0
      matched_ua = nil
      if user_agent.starts_with('SAMSUNG') || user_agent.starts_with('SEC-') || user_agent.starts_with('SCH-')
        tolerance = user_agent.first_slash
      elsif user_agent.starts_with('Samsung') || user_agent.starts_with('SPH') || user_agent.starts_with('SGH')
        tolerance = user_agent.first_space
      else
        tolerance = user_agent.second_slash
      end
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        if user_agent.starts_with('SAMSUNG')
          tolerance = 8
          matched_ua = ld_match(user_agent, tolerance)
        else
          tolerance = user_agent.index_of_or_length('/', user_agent.index('Samsung'))
          matched_ua = ris_match(user_agent, tolerance)
        end
      end
      return matched_ua
    end

    def matcher_blackberry(user_agent)
      tolerance = 0
      matched_ua = nil
      if user_agent.starts_with('BlackBerry')
        tolerance = user_agent.ordinal_index_of(';', 3)
      else
        tolerance = user_agent.first_slash
      end
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
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
          }.each_pair do |vercode, device_ua|
            if vercode.index(vercode)
              return device_ua
            end
          end
        end
      end
      return matched_ua
    end

    def matcher_sonyericsson(user_agent)
      tolerance = 0
      matched_ua = nil
      if user_agent.starts_with('SonyEricsson')
        tolerance = user_agent.first_slash - 1
      else
        tolerance = user_agent.second_slash
      end
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        tolerance = 14
        matched_ua = ris_match(user_agent, tolerance)
      end
      return matched_ua
    end

    def matcher_motorola(user_agent)
      tolerance = 5
      matched_ua = nil
      if user_agent.starts_with('Mot-') || user_agent.starts_with('MOT-') || user_agent.starts_with('Motorola')
        matched_ua = ris_match(user_agent, tolerance)
      else
        matched_ua = ld_match(user_agent, tolerance)
      end
      if matched_ua.nil?
        return 'DO_NOT_MATCH_MIB_2_2' if user_agent.contains('MIB/2.2') || user_agent.contains('MIB/BER2.2')
      end
      return matched_ua
    end

    def matcher_alcatel(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_apple(user_agent)
      tolerance = 0
      matched_ua = nil
      if user_agent.starts_with('Apple')
        tolerance = user_agent.ordinal_index_of(' ', 3)
        tolerance = user_agent.length if tolerance == -1
      else
        tolerance = user_agent.ordinal_index_of(';', 0)
      end
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = case
        when user_agent.contains('iPod')
          'Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/3A100a Safari/419.3'
        when user_agent.contains('iPad')
          'Mozilla/5.0 (iPad; U; CPU iPhone OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7D11'
        when user_agent.contains('iPhone')
          'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A538a Safari/419.3'
        else
          Settings::GENERIC
        end
      end
      return matched_ua
    end

    def matcher_benq(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_docomo(user_agent)
      tolerance = 0
      if user_agent.num_slashes >= 2
        tolerance = user_agent.second_slash
      else
        tolerance = user_agent.first_open_paren
      end
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        version_index = 7
        matched_ua = case
        when user_agent[version_index] == '2'
          'DO_NOT_MATCH_DOCOMO_GENERIC_JAP_2'
        else
          'DO_NOT_MATCH_DOCOMO_GENERIC_JAP_1'
        end
      end
      return matched_ua
    end

    def matcher_grundig(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_htc(user_agent)
      tolerance = user_agent.first_slash
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        tolerance = 6
        matched_ua = ris_match(user_agent, tolerance)
      end
      return matched_ua
    end

    def matcher_kddi(user_agent)
      tolerance = 0
      if user_agent.starts_with('KDDI/')
        tolerance = user_agent.second_slash
      else
        tolerance = user_agent.first_slash
      end
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = 'DO_NOT_MATCH_UP.Browser/6.2'
      end
      return matched_ua
    end

    def matcher_kyocera(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_lg(user_agent)
      tolerance = user_agent.index_of_or_length('/', user_agent.index('LG'))
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        tolerance = 7
        matched_ua = ris_match(user_agent, tolerance)
      end
      return matched_ua
    end

    def matcher_mitsubishi(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_nec(user_agent)
      tolerance = user_agent.first_slash
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        tolerance = 2
        matched_ua = ris_match(user_agent, tolerance)
      end
      return matched_ua
    end

    def matcher_nintendo(user_agent)
      @device = ld_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = case
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
      return matched_ua
    end

    def matcher_panasonic(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_pantech(user_agent)
      tolerance = 5
      if !user_agent.starts_with('Pantech')
        tolerance = user_agent.first_slash
        matched_ua = ris_match(user_agent, tolerance)
      end
      matched_ua = ris_match(user_agent, tolerance)
      return matched_ua
    end

    def matcher_philips(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_portalmmm(user_agent)
      return Settings::GENERIC
    end

    def matcher_qtek(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_sagem(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_sharp(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_siemens(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_spv(user_agent)
      pos = user_agent.index(';')
      tolerance = pos || user_agent.index('SPV')
      return ris_match(user_agent, tolerance)
    end

    def matcher_toshiba(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_vodafone(user_agent)
      tolerance = user_agent.first_slash
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = ld_match(user_agent)
      end
      return matched_ua
    end

    # mobile browsers
    def matcher_android(user_agent)
      matched_ua = 'DO_NOT_MATCH_GENERIC_ANDROID'
      if user_agent.contains('Froyo')
        matched_ua = 'DO_NOT_MATCH_ANDROID_2_2'
      elsif user_agent =~ /#Android[\s\/](\d).(\d)#/
        version = "generic_android_ver#{$1}_#{$2}"
        version = 'generic_android_ver2' if version == 'generic_android_ver2_0'
        android_uas = {
          'generic_android_ver1_5'  => 'DO_NOT_MATCH_ANDROID_1_5',
          'generic_android_ver1_6'  => 'DO_NOT_MATCH_GENERIC_ANDROID_1_6',
          'generic_android_ver2'    => 'DO_NOT_MATCH_GENERIC_ANDROID_2_0',
          'generic_android_ver2_1'  => 'DO_NOT_MATCH_GENERIC_ANDROID_2_1',
          'generic_android_ver2_2'  => 'DO_NOT_MATCH_ANDROID_2_2',
        }
        matched_ua = android_uas[version] if android_uas.has_key?(version)
      end
      return matched_ua
    end

    def matcher_operamini(user_agent)
      tolerance = user_agent.first_slash
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = 'DO_NOT_MATCH_GENERIC_OPERA_MINI_VERSION_1';
        if user_agent =~ /#Opera Mini\/([1-5])#/
          matched_ua = "DO_NOT_MATCH_BROWSER_OPERA_MINI_#{$1}_0"
        elsif user_agent.contains('Opera Mobi')
          matched_ua = 'DO_NOT_MATCH_GENERIC_OPERA_MINI_VERSION_4'
        end
      end
      return matched_ua
    end

    def matcher_windowsce(user_agent)
      tolerance = 3
      matched_ua = ld_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = 'DO_NOT_MATCH_REMOVE_GENERIC_MS_MOBILE_BROWSER_VER1'
      end
      return matched_ua
    end

    # robots
    def matcher_bot(user_agent)
      tolerance = user_agent.first_slash
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = 'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
      end
      return matched_ua
    end

    # desktop browsers
    def matcher_msie(user_agent)
      if user_agent =~ /^Mozilla\/4\.0 \(compatible; MSIE (\d)\.(\d);/
        version = $1.to_i
        version_sub = $2.to_i
        matched_ua = case
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
        tolerance = user_agent.first_slash
        matched_ua = ris_match(user_agent, tolerance)
      end
      if matched_ua.nil?
        if user_agent.contains(['SLCC1', 'Media Center PC', '.NET CLR', 'OfficeLiveConnector'])
          matched_ua'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
        else
          matched_ua = Settings::GENERIC
        end
      end
      return matched_ua
    end

    def matcher_firefox(user_agent)
      if user_agent =~ /Firefox\/(\d)\.(\d)/
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
        tolerance = 5
        matched_ua = ld_match(user_agent, tolerance)
      end
      return matched_ua
    end

    def matcher_chrome(user_agent)
      tolerance = user_agent.index_of_or_length('/', user_agent.index('Chrome'))
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = 'Chrome'
      end
      return matched_ua
    end

    def matcher_konqueror(user_agent)
      tolerance = user_agent.first_slash
      return ris_match(user_agent, tolerance)
    end

    def matcher_opera(user_agent)
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
      if matched_ua.nil?
        tolerance = 5
        matched_ua = ld_match(user_agent, tolerance)
      end
      matched_ua = 'Opera' if matched_ua.nil?
      return matched_ua
    end

    def matcher_safari(user_agent)
      tolerance = user_agent.first_slash
      matched_ua = ris_match(user_agent, tolerance)
      if matched_ua.nil?
        matched_ua = case
        when user_agent.contains('Macintosh') || user_agent.contains('Windows')
          'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
        else
          Settings::GENERIC
        end
      end
      return matched_ua
    end

    def matcher_aol(user_agent)
      return 'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
    end
  end
end
