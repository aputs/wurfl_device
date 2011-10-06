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
      user_agent = @user_agent.cleaned
      if @device.nil?
        index_matcher = get_index(user_agent)
        matcher = "matcher_#{index_matcher.downcase}"
        if self.respond_to?(matcher)
          self.send(matcher, user_agent) 
        else
          if user_agent =~ /^Mozilla/i
            tolerance = 5
            @device = ld_match(user_agent, tolerance)
          else
            tolerance = user_agent.first_slash
            @device = ris_match(user_agent, tolerance)
          end
        end
      end

      # last attempts
      if @device.nil?
        last_attempts(user_agent)
      end

      WurflDevice.save_device_in_ua_cache(@user_agent, @device)

      return self
    end

    def ris_match(user_agent, tolerance)
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
      tolerance = 7 if tolerance.nil?
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

  private
    # user agent matchers
    def last_attempts(user_agent)
      device_id = case
      # OpenWave
      when user_agent.contains('UP.Browser/7.2')
        'opwv_v72_generic'
      when user_agent.contains('UP.Browser/7')
        'opwv_v7_generic'
      when user_agent.contains('UP.Browser/6.2')
        'opwv_v62_generic'
      when user_agent.contains('UP.Browser/6')
        'opwv_v6_generic'
      when user_agent.contains('UP.Browser/5')
        'upgui_generic'
      when user_agent.contains('UP.Browser/4')
        'uptext_generic'
      when user_agent.contains('UP.Browser/3')
        'uptext_generic'
      # Series 60
      when user_agent.contains('Series60')
        'nokia_generic_series60'
      when user_agent.contains('Series80')
        'nokia_generic_series80'
      # Access/Net Front
      when user_agent.contains(['NetFront/3.0', 'ACS-NF/3.0'])
        'generic_netfront_ver3'
      when user_agent.contains(['NetFront/3.1', 'ACS-NF/3.1'])
        'generic_netfront_ver3_1'
      when user_agent.contains(['NetFront/3.2', 'ACS-NF/3.2'])
        'generic_netfront_ver3_2'
      when user_agent.contains(['NetFront/3.3', 'ACS-NF/3.3'])
        'generic_netfront_ver3_3'
      when user_agent.contains('NetFront/3.4')
        'generic_netfront_ver3_4'
      when user_agent.contains('NetFront/3.5')
        'generic_netfront_ver3_5'
      # Contains Mozilla/, but not at the beginning of the UA
      when user_agent.starts_with('Mozilla/') || @user_agent.contains('Mozilla/')
        WurflDevice::Constants::GENERIC_XHTML
      # Obigo
      when user_agent.contains(['ObigoInternetBrowser/Q03C', 'AU-MIC/2', 'AU-MIC-', 'AU-OBIGO', 'Obigo/Q03', 'Obigo/Q04', 'ObigoInternetBrowser/2', 'Teleca Q03B1'])
        WurflDevice::Constants::GENERIC_XHTML
      # DoCoMo
      when user_agent.starts_with('DoCoMo') || @user_agent.starts_with('KDDI')
        'docomo_generic_jap_ver1'
      # Generic Mozilla
      when user_agent.contains(['Mozilla/4.0', 'Mozilla/5.0', 'Mozilla/6.0'])
        WurflDevice::Constants::GENERIC_WEB_BROWSER
      else
        WurflDevice::Constants::GENERIC
      end
      @device = WurflDevice.get_device_from_id(device_id)
    end

    # mobile user agents
    def match_nokia(user_agent)
      tolerance = user_agent.index_of_or_length(['/', ' '], user_agent.index('Nokia'))
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_samsung(user_agent)
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
      if user_agent.starts_with('BlackBerry')
        tolerance = user_agent.ordinal_index_of(';', 3)
      else
        tolerance = user_agent.first_slash
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        if user_agent =~ /\#Black[Bb]erry[^\/\s]+\/(\d.\d)\#/
          versions = {
            '2.' => 'blackberry_generic_ver2',
            '3.2' => 'blackberry_generic_ver3_sub2',
            '3.3' => 'blackberry_generic_ver3_sub30',
            '3.5' => 'blackberry_generic_ver3_sub50',
            '3.6' => 'blackberry_generic_ver3_sub60',
            '3.7' => 'blackberry_generic_ver3_sub70',
            '4.1' => 'blackberry_generic_ver4_sub10',
            '4.2' => 'blackberry_generic_ver4_sub20',
            '4.3' => 'blackberry_generic_ver4_sub30',
            '4.5' => 'blackberry_generic_ver4_sub50',
            '4.6' => 'blackberry_generic_ver4_sub60',
            '4.7' => 'blackberry_generic_ver4_sub70',
            '4.' => 'blackberry_generic_ver4',
            '5.' => 'blackberry_generic_ver5',
            '6.' => 'blackberry_generic_ver6',
          }.each_pair do |version, device_id|
            if version.index($1)
              @device = Device.new(device_id)
              break
            end
          end
        end
      end
    end

    def matcher_sonyericsson(user_agent)
      if user_agent.starts_with('SonyEricsson')
        tolerance = user_agent.first_slash - 1
        @device = ris_match(user_agent, tolerance)
      else
        tolerance = user_agent.second_slash
        @device = ris_match(user_agent, tolerance)
      end
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
        @device = Device.new('mot_mib22_generic') if @user_agent.contains('MIB/2.2') || @user_agent.contains('MIB/BER2.2')
      end
    end

    def matcher_alcatel(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_apple(user_agent)
      if user_agent.starts_with('Apple')
        tolerance = user_agent.ordinal_index_of(' ')
        tolerance = user_agent.length if tolerance == -1
      else
        tolerance = user_agent.ordinal_index_of(';')
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        device_id = case
        when user_agent.contains('iPod')
          'apple_ipod_touch_ver1'
        when user_agent.contains('iPad')
          'apple_ipad_ver1'
        when user_agent.contains('iPhone')
          'apple_iphone_ver1'
        else
          WurfDevice::Contants::GENERIC
        end
        @device = Device.new(device_id)
      end
    end

    def matcher_benq(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_docomo(user_agent)
      if user_agent.num_slashes >= 2
        tolerance = user_agent.second_slash
      else
        tolerance = user_agent.first_open_paren
      end
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        version_index = 7
        device_id = case
        when user_agent[version_index] == '2'
          'docomo_generic_jap_ver2'
        else
          'docomo_generic_jap_ver1'
        end
        @device = Device.new(device_id)
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
      if user_agent.starts_with('KDDI/')
        tolerance = user_agent.second_slash
        @device = ris_match(user_agent, tolerance)
      else
        tolerance = user_agent.first_slash
        @device = ris_match(user_agent, tolerance)
      end
      if @device.nil?
        @device = Device.new('opwv_v62_generic')
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
        device_id = case
        when user_agent.contains('Nintendo Wii')
          'nintendo_wii_browser'
        when user_agent.contains('Nintendo DSi')
          'nintendo_dsi_ver1'
        when user_agent.starts_with('Mozilla/') && user_agent.contains('Nitro') && user_agent.contains('Opera')
          'nintendo_ds_ver1'
        else
          'nintendo_wii_browser'
        end
        @device = Device.new(device_id)
      end
    end

    def matcher_panasonic(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_pantech(user_agent)
      if user_agent.starts_with('Pantech')
        tolerance = 5
        @device = ld_match(user_agent, tolerance)
      else
        tolerance = user_agent.first_slash
        @device = ris_match(user_agent, tolerance)
      end
    end

    def matcher_philips(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_portalmmm(user_agent)
      @device = Device.new(WurflDevice::Constants::GENERIC)
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
      device_id = 'generic_android'
      if user_agent.contains('Froyo')
        device_id = Device.new('generic_android_ver2_2')
      elsif user_agent =~ /#Android[\s\/](\d).(\d)#/
        version = "generic_android_ver#{$1}_#{$2}"
        version = 'generic_android_ver2' if version == 'generic_android_ver2_0'
        device_id = version if [
          'generic_android',
          'generic_android_ver1_5',
          'generic_android_ver1_6',
          'generic_android_ver2',
          'generic_android_ver2_1',
          'generic_android_ver2_2',
        	].include?(version)
      end
      @device = Device.new(device_id)
    end

    def matcher_operamini(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        device_id = 'browser_opera_mini_release1';
        if user_agent =~ /#Opera Mini\/([1-5])#/
          device_id = "browser_opera_mini_release#{$1}"
        elsif user_agent.contains('Opera Mobi')
          device_id = 'browser_opera_mini_release4'
        end
        @device = Device.new(device_id)
      end
    end

    def matcher_windowsce(user_agent)
      tolerance = 3
      @device = ld_match(user_agent, tolerance)
      if @device.nil?
        @device = Device.new('generic_ms_mobile_browser_ver1')
      end
    end

    # robots
    def matcher_bot(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        @device = Device.new(WurflDevice::Constants::GENERIC_WEB_BROWSER)
      end
    end

    # desktop browsers
    def matcher_msie(user_agent)
      if user_agent =~ /^Mozilla\/4\.0 \(compatible; MSIE (\d)\.(\d);/
        version = $1.to_i
        version_sub = $2.to_i
        device_id = case
        when version == 7
          'msie_7'
        when version == 8
          'msie_8'
        when version == 6
          'msie_6'
        when version == 4
          'msie_4'
        when version == 5
          version_sub == 5 ? 'msie_5_5' : 'msie_5'
        else
          'msie'
        end
        @device = Device.new(device_id)
      end
      user_agent.sub!(/( \.NET CLR [\d\.]+;?| Media Center PC [\d\.]+;?| OfficeLive[a-zA-Z0-9\.\d]+;?| InfoPath[\.\d]+;?)/, '')
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        if user_agent.contains(['SLCC1', 'Media Center PC', '.NET CLR', 'OfficeLiveConnector'])
          @device = Device.new(WurfDevice::Constants::GENERIC_WEB_BROWSER)
        else
          @device = Device.new(WurfDevice::Constants::GENERIC)
        end
      end
    end

    def matcher_firefox(user_agent)
      if user_agent =~ /Firefox\/(\d)\.(\d)/
        version = $1.to_i
        version_sub = $2.to_i
        device_id = case
        when version == 3
          version_sub == 5 ? 'firefox_3_5' : 'firefox_3'
        when version == 2
          'firefox_2'
        when version == 1
          version_sub == 5 ? 'firefox_1_5' : 'firefox_1'
        else
          nil
        end
        @device = Device.new(device_id) unless device_id.nil?
      else
        tolerance = 5
        @device = ld_match(user_agent, tolerance)
      end
    end

    def matcher_chrome(user_agent)
      tolerance = user_agent.index_of_or_length('/', user_agent.index('Chrome'))
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        @device = Device.new('google_chrome')
      end
    end

    def matcher_konqueror(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
    end

    def matcher_opera(user_agent)
      device_id = case
      when user_agent.contains('Opera/10')
        'opera_10'
      when user_agent.contains('Opera/9')
        'opera_9'
      when user_agent.contains('Opera/8')
        'opera_8'
      when user_agent.contains('Opera/7')
        'opera_7'
      else
        nil
      end
      @device = Device.new(device_id) unless device_id.nil?
      if @device.nil?
        tolerance = 5
        @device = ld_match(user_agent, tolerance)
      end
      @device = Device.new('opera') if @device.nil?
    end

    def matcher_safari(user_agent)
      tolerance = user_agent.first_slash
      @device = ris_match(user_agent, tolerance)
      if @device.nil?
        device_id = case
        when user_agent.contains('Macintosh') || user_agent.contains('Windows')
          WurflDevice::Constants::GENERIC_WEB_BROWSER
        else
          WurflDevice::Constants::GENERIC
        end
        @device = Device.new(device_id)
      end
    end

    def matcher_aol(user_agent)
      @device = Device.new(WurflDevice::Constants::GENERIC_WEB_BROWSER)
    end
  end
end
