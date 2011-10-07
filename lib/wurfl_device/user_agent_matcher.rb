require 'text'

module WurflDevice
  class UserAgentMatcher
    attr_accessor :user_agent, :device

    def match(user_agent)
      @user_agent = UserAgent.new(user_agent)

      # exact match
      @device = WurflDevice.get_device_from_ua_cache(@user_agent)
      @device = WurflDevice.get_device_from_ua_cache(@user_agent.cleaned) if @device.nil?

      # already in cache so return immediately
      return self if !@device.nil? && @device.is_valid?

      # ris match
      if @device.nil?
        index_matcher = get_index(@user_agent)
        matcher = "matcher_#{index_matcher.downcase}"
        if self.respond_to?(matcher)
          self.send(matcher, @user_agent) 
        else
          if @user_agent =~ /^Mozilla/i
            tolerance = 5
            @device = ld_match(@user_agent, tolerance)
          else
            tolerance = @user_agent.first_slash
            @device = ris_match(@user_agent, tolerance)
          end
        end
      end

      # last attempts
      if @device.nil?
        last_attempts(@user_agent)
      end

      WurflDevice.save_device_in_ua_cache(@user_agent, @device) if @device.is_valid?

      return self
    end

    def ris_match(user_agent, tolerance=nil)
      tolerance = WurflDevice::Constants::WORST_MATCH if tolerance.nil?
      device = nil
      user_agent_list = WurflDevice.get_user_agents_in_index(get_index(user_agent))
      curlen = user_agent.length
      while curlen >= tolerance
        user_agent_list.each do |ua|
          next if ua.length < curlen
          if ua.index(user_agent) == 0
            device = WurflDevice.get_device_from_ua_cache(ua, true)
            break
          end
        end
        break unless device.nil?
        user_agent = user_agent.slice(0, curlen-1)
        curlen = user_agent.length
      end
      return device
    end

    def ld_match(user_agent, tolerance=nil)
      tolerance = WurflDevice::Constants::WORST_MATCH if tolerance.nil?
      device = nil
      user_agent_list = WurflDevice.get_user_agents_in_index(get_index(user_agent))

      length = user_agent.length
      best = tolerance
      current = 0
      match = nil
      user_agent_list.select do |ua|
        next if !ua.length.between?(length - tolerance, length + tolerance)
        current = Text::Levenshtein.distance(ua, user_agent)
        if current <= best
          best = current
          match = ua
        end
      end

      device = WurflDevice.get_device_from_ua_cache(match, true)
      return device
    end

    def get_index(user_agent)
      ua = UserAgent.new(user_agent)
      # Process MOBILE user agents
      unless ua.is_desktop_browser?
        return 'Nokia' if ua.contains('Nokia')
        return 'Samsung' if ua.contains(['Samsung/SGH', 'SAMSUNG-SGH']) || ua.starts_with(['SEC-', 'Samsung', 'SAMSUNG', 'SPH', 'SGH', 'SCH']) || ua.starts_with('samsung', true)
        return 'BlackBerry' if ua.contains('blackberry', true)
        return 'SonyEricsson' if ua.contains('Sony')
        return 'Motorola' if ua.starts_with(['Mot-', 'MOT-', 'MOTO', 'moto']) || ua.contains('Motorola')

        return 'Alcatel' if ua.starts_with('alcatel', true)
        return 'Apple' if ua.contains(['iPhone', 'iPod', 'iPad', '(iphone'])
        return 'BenQ' if ua.starts_with('benq', true)
        return 'DoCoMo' if ua.starts_with('DoCoMo')
        return 'Grundig' if ua.starts_with('grundig', true)
        return 'HTC' if ua.contains(['HTC', 'XV6875'])
        return 'Kddi' if ua.contains('KDDI-')
        return 'Kyocera' if ua.starts_with(['kyocera', 'QC-', 'KWC-'])
        return 'LG' if ua.starts_with('lg', true)
        return 'Mitsubishi' if ua.starts_with('Mitsu')
        return 'Nec' if ua.starts_with(['NEC-', 'KGT'])
        return 'Nintendo' if ua.contains('Nintendo') || (ua.starts_with('Mozilla/') && ua.starts_with('Nitro') && ua.starts_with('Opera'))
        return 'Panasonic' if ua.contains('Panasonic')
        return 'Pantech' if ua.starts_with(['Pantech', 'PT-', 'PANTECH', 'PG-'])
        return 'Philips' if ua.starts_with('philips', true)
        return 'Portalmmm' if ua.starts_with('portalmmm')
        return 'Qtek' if ua.starts_with('Qtek')
        return 'Sagem' if ua.starts_with('sagem', true)
        return 'Sharp' if ua.starts_with('sharp', true)
        return 'Siemens' if ua.starts_with('SIE-')
        return 'SPV' if ua.starts_with('SPV')
        return 'Toshiba' if ua.starts_with('Toshiba')
        return 'Vodafone' if ua.starts_with('Vodafone')

        # mobile browsers
        return 'Android' if ua.contains('Android')
        return 'OperaMini' if ua.contains(['Opera Mini', 'Opera Mobi'])
        return 'WindowsCE' if ua.contains('Mozilla/') && ua.contains('Windows CE')
      end

      # Process Robots (Web Crawlers and the like)
      return 'Bot' if ua.is_robot?

      # Process NON-MOBILE user agents
      unless ua.is_mobile_browser?
        return 'MSIE' if ua.starts_with('Mozilla') && ua.contains('MSIE') && !ua.contains(['Opera', 'armv', 'MOTO', 'BREW'])
        return 'Firefox' if ua.contains('Firefox') && !ua.contains(['Sony', 'Novarra', 'Opera'])
        return 'Chrome' if ua.contains('Chrome') 
        return 'Konqueror' if ua.contains('Konqueror')
        return 'Opera' if ua.contains('Opera')
        return 'Safari' if ua.starts_with('Mozilla') && ua.contains('Safari')
        return 'AOL' if ua.contains(['AOL', 'America Online']) || ua.contains('aol 9', true)
      end

      return 'CatchAll'
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
      when user_agent.starts_with('Mozilla/') || user_agent.contains('Mozilla/')
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
        WurflDevice::Constants::GENERIC
      end
      @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
    end

    # mobile user agents
    def matcher_nokia(user_agent)
      tolerance = user_agent.index_of_or_length(['/', ' '], user_agent.index('Nokia'))
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_samsung(user_agent)
      tolerance = 0
      if user_agent.starts_with('SAMSUNG') || user_agent.starts_with('SEC-') || user_agent.starts_with('SCH-')
        tolerance = user_agent.first_slash
      elsif user_agent.starts_with('Samsung') || user_agent.starts_with('SPH') || user_agent.starts_with('SGH')
        tolerance = user_agent.first_space
      else
        tolerance = user_agent.second_slash
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        if user_agent.starts_with('SAMSUNG')
          tolerance = 8
          @device = ld_match(user_agent, tolerance)
        else
          tolerance = user_agent.index_of_or_length('/', user_agent.index('Samsung'))
          @device = ris_match(user_agent, tolerance)
        end
      end
    end

    def matcher_blackberry(user_agent)
      tolerance = 0
      if user_agent.starts_with('BlackBerry')
        tolerance = user_agent.ordinal_index_of(';', 3)
      else
        tolerance = user_agent.first_slash
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        if user_agent =~ /Black[Bb]erry[^\/\s]+\/(\d\.\d)/
          versions = {
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
            if $1.index(vercode)
              @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
              break
            end
          end
        end
      end
    end

    def matcher_sonyericsson(user_agent)
      tolerance = 0
      if user_agent.starts_with('SonyEricsson')
        tolerance = user_agent.first_slash - 1
      else
        tolerance = user_agent.second_slash
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        tolerance = 14
        @device = ris_match(user_agent, tolerance)
      end
    end

    def matcher_motorola(user_agent)
      tolerance = 5
      if user_agent.starts_with('Mot-') || user_agent.starts_with('MOT-') || user_agent.starts_with('Motorola')
        @device = ris_match(user_agent, tolerance)
      else
        @device = ld_match(user_agent, tolerance)
      end
      if @device.nil?
        @device = WurflDevice.get_device_from_ua_cache('DO_NOT_MATCH_MIB_2_2', true) if user_agent.contains('MIB/2.2') || user_agent.contains('MIB/BER2.2')
      end
    end

    def matcher_alcatel(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_apple(user_agent)
      tolerance = 0
      if user_agent.starts_with('Apple')
        tolerance = user_agent.ordinal_index_of(' ', 3)
        tolerance = user_agent.length if tolerance == -1
      else
        tolerance = user_agent.ordinal_index_of(';', 0)
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        device_ua = case
        when user_agent.contains('iPod')
          'Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/3A100a Safari/419.3'
        when user_agent.contains('iPad')
          'Mozilla/5.0 (iPad; U; CPU iPhone OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7D11'
        when user_agent.contains('iPhone')
          'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A538a Safari/419.3'
        else
          WurfDevice::Contants::GENERIC
        end
        @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
      end
    end

    def matcher_benq(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_docomo(user_agent)
      tolerance = 0
      if user_agent.num_slashes >= 2
        tolerance = user_agent.second_slash
      else
        tolerance = user_agent.first_open_paren
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        version_index = 7
        device_ua = case
        when user_agent[version_index] == '2'
          'DO_NOT_MATCH_DOCOMO_GENERIC_JAP_2'
        else
          'DO_NOT_MATCH_DOCOMO_GENERIC_JAP_1'
        end
        @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
      end
    end

    def matcher_grundig(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_htc(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        tolerance = 6
        @device = ris_match(user_agent, tolerance)
      end
    end

    def matcher_kddi(user_agent)
      tolerance = 0
      if user_agent.starts_with('KDDI/')
        tolerance = user_agent.second_slash
      else
        tolerance = user_agent.first_slash
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        @device = WurflDevice.get_device_from_ua_cache('DO_NOT_MATCH_UP.Browser/6.2', true)
      end
    end

    def matcher_kyocera(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_lg(user_agent)
      tolerance = user_agent.index_of_or_length('/', user_agent.index('LG'))
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        tolerance = 7
        @device = ris_match(user_agent, tolerance)
      end
    end

    def matcher_mitsubishi(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_nec(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        tolerance = 2
        @device = ris_match(user_agent, tolerance)
      end
    end

    def matcher_nintendo(user_agent)
      @device = ld_match(user_agent, tolerance)
      if @device.nil?
        device_ua = case
        when user_agent.contains('Nintendo Wii')
          'Opera/9.00 (Nintendo Wii; U; ; 1621; en)'
        when user_agent.contains('Nintendo DSi')
          'Opera/9.50 (Nintendo DSi; Opera/483; U; en-US)'
        when user_agent.starts_with('Mozilla/') && user_agent.contains('Nitro') && user_agent.contains('Opera')
          'Mozilla/4.0 (compatible; MSIE 6.0; Nitro) Opera 8.50 [en]'
        else
          'Opera/9.00 (Nintendo Wii; U; ; 1621; en)'
        end
        @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
      end
    end

    def matcher_panasonic(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_pantech(user_agent)
      tolerance = 5
      if !user_agent.starts_with('Pantech')
        tolerance = user_agent.first_slash
        @device = ris_match(user_agent, tolerance)
      end
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_philips(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_portalmmm(user_agent)
      @device = WurflDevice.get_device_from_ua_cache(WurflDevice::Constants::GENERIC, true)
    end

    def matcher_qtek(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_sagem(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_sharp(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_siemens(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_spv(user_agent)
      pos = user_agent.index(';')
      tolerance = pos || user_agent.index('SPV')
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_toshiba(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_vodafone(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        @device = ld_match(user_agent)
      end
    end

    # mobile browsers
    def matcher_android(user_agent)
      device_ua = 'DO_NOT_MATCH_GENERIC_ANDROID'
      if user_agent.contains('Froyo')
        device_ua = 'DO_NOT_MATCH_ANDROID_2_2'
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
        device_ua = android_uas[version] if android_uas.has_key?(version)
      end
      @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
    end

    def matcher_operamini(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        device_ua = 'DO_NOT_MATCH_GENERIC_OPERA_MINI_VERSION_1';
        if user_agent =~ /#Opera Mini\/([1-5])#/
          device_ua = "DO_NOT_MATCH_BROWSER_OPERA_MINI_#{$1}_0"
        elsif user_agent.contains('Opera Mobi')
          device_ua = 'DO_NOT_MATCH_GENERIC_OPERA_MINI_VERSION_4'
        end
        @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
      end
    end

    def matcher_windowsce(user_agent)
      tolerance = 3
      @device = ld_match(user_agent, tolerance)
      if @device.nil?
        @device = WurflDevice.get_device_from_ua_cache('DO_NOT_MATCH_REMOVE_GENERIC_MS_MOBILE_BROWSER_VER1', true)
      end
    end

    # robots
    def matcher_bot(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        @device = WurflDevice.get_device_from_ua_cache('DO_NOT_MATCH_GENERIC_WEB_BROWSER', true)
      end
    end

    # desktop browsers
    def matcher_msie(user_agent)
      if user_agent =~ /^Mozilla\/4\.0 \(compatible; MSIE (\d)\.(\d);/
        version = $1.to_i
        version_sub = $2.to_i
        device_ua = case
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
        @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
      else
        user_agent.sub!(/( \.NET CLR [\d\.]+;?| Media Center PC [\d\.]+;?| OfficeLive[a-zA-Z0-9\.\d]+;?| InfoPath[\.\d]+;?)/, '')
        tolerance = user_agent.first_slash
        @device = ris_match(user_agent, tolerance)
      end
      if @device.nil?
        if user_agent.contains(['SLCC1', 'Media Center PC', '.NET CLR', 'OfficeLiveConnector'])
          @device = WurflDevice.get_device_from_ua_cache('DO_NOT_MATCH_GENERIC_WEB_BROWSER', true)
        else
          @device = WurflDevice.get_device_from_ua_cache(WurfDevice::Constants::GENERIC, true)
        end
      end
    end

    def matcher_firefox(user_agent)
      if user_agent =~ /Firefox\/(\d)\.(\d)/
        version = $1.to_i
        version_sub = $2.to_i
        device_ua = case
        when version == 3
          version_sub == 5 ? 'Firefox/3.5' : 'Firefox/3.0'
        when version == 2
          'firefox_2'
        when version == 1
          version_sub == 5 ? 'Firefox/1.5' : 'Firefox/1.0'
        else
          nil
        end
        @device = WurflDevice.get_device_from_ua_cache(device_ua, true) unless device_ua.nil?
      else
        tolerance = 5
        @device = ld_match(user_agent, tolerance)
      end
    end

    def matcher_chrome(user_agent)
      tolerance = user_agent.index_of_or_length('/', user_agent.index('Chrome'))
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        @device = WurflDevice.get_device_from_ua_cache('Chrome', true)
      end
    end

    def matcher_konqueror(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_opera(user_agent)
      device_ua = case
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
      @device = WurflDevice.get_device_from_ua_cache(device_ua, true) unless device_ua.nil?
      if @device.nil?
        tolerance = 5
        @device = ld_match(user_agent, tolerance)
      end
      @device = WurflDevice.get_device_from_ua_cache('Opera', true) if @device.nil?
    end

    def matcher_safari(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        device_ua = case
        when user_agent.contains('Macintosh') || user_agent.contains('Windows')
          'DO_NOT_MATCH_GENERIC_WEB_BROWSER'
        else
          WurflDevice::Constants::GENERIC
        end
        @device = WurflDevice.get_device_from_ua_cache(device_ua, true)
      end
    end

    def matcher_aol(user_agent)
      @device = WurflDevice.get_device_from_ua_cache('DO_NOT_MATCH_GENERIC_WEB_BROWSER', true)
    end
  end
end
