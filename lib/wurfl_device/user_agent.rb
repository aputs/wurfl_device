# encoding: utf-8
module WurflDevice
  class UserAgent < String
    ROBOTS            = [ 'bot', 'crawler', 'spider', 'novarra', 'transcoder', 'yahoo! searchmonkey', 'yahoo! slurp', 'feedfetcher-google', 'toolbar', 'mowser', 'bjaaland' ]
    DESKTOP_BROWSERS  = [ 'slcc1', '.net clr', 'wow64', 'media center pc', 'funwebproducts', 'macintosh', 'aol 9.', 'america online browser', 'googletoolbar' ]
    MOBILE_BROWSERS   = [
      'cldc', 'symbian', 'midp', 'j2me', 'mobile', 'wireless', 'palm', 'phone', 'pocket pc', 'pocketpc', 'netfront',
      'bolt', 'iris', 'brew', 'openwave', 'windows ce', 'wap2.', 'android', 'opera mini', 'opera mobi', 'maemo', 'fennec',
      'blazer', 'vodafone', 'wp7', 'armv'
    ]

    def initialize(str='')
      begin
        str.encode!("UTF-8", undef: :replace) unless str.encoding.name =~ /UTF/
      rescue => e
        raise UserAgentError, e.message
      end
      super(str).strip!
    end

    def is_desktop_browser?
      ua = self.downcase
      DESKTOP_BROWSERS.each do |sig|
        return true if ua.index(sig)
      end
      return false
    end

    def is_mobile_browser?
      ua = self.downcase
      return false if self.is_desktop_browser?
      return true if ua =~ /[^\d]\d{3}x\d{3}/
      MOBILE_BROWSERS.each do |sig|
        return true if ua.index(sig)
      end
      return false
    end

    def is_robot?
      ua = self.downcase
      ROBOTS.each do |sig|
        return true if ua.index(sig)
      end
      return false
    end

    def first_slash
      pos = self.index('/')
      return self.length if pos.nil?
      return pos
    end

    def second_slash
      first = self.index('/')
      return self.length if first.nil?
      second = self.index('/', first + 1)
      return self.length if second.nil?
      return second
    end

    def num_slashes
      self.count('/')
    end

    def first_space
      pos = self.index(' ')
      return self.length if pos.nil?
      return pos
    end

    def first_open_paren
      pos = self.index('(')
      return self.length if pos.nil?
      return pos
    end

    def contains(find, ignore_case=false)
      user_agent = self.downcase if ignore_case
      user_agent = self unless ignore_case
      if find.kind_of?(Array)
        find.map do |needle|
          needle = needle.downcase if ignore_case
          return true unless user_agent.index(needle).nil?
        end
        return false
      else
        find = find.downcase if ignore_case
        return true unless user_agent.index(find).nil?
        return false
      end
    end

    def starts_with(find, ignore_case=false)
      user_agent = self.downcase if ignore_case
      user_agent = self unless ignore_case
      if find.kind_of?(Array)
        find.map do |needle|
          needle = needle.downcase if ignore_case
          return true if user_agent.index(needle) == 0
        end
        return false
      else
        find = find.downcase if ignore_case
        return true if user_agent.index(find) == 0
        return false
      end
    end

    def index_of_or_length(target, starting_index=nil)
      length = self.length
      return length if starting_index.nil?
      if target.kind_of?(Array)
        target.map do |needle|
          next if needle.nil?
          pos = self.index(needle, starting_index)
          return pos unless pos.nil?
        end
        return length
      else
        pos = self.index(target, starting_index)
        return length if pos.nil?
        return pos unless pos.nil?
      end
    end

    def ordinal_index_of(needle, ordinal)
      return -1 if self.nil? || self.empty? || ordinal.is_a?(Integer)
      found = 0
      index = -1
      begin
        index = self.index(needle, index + 1)
        index = index.is_a?(Integer) ? index : -1
        return index if index < 0
        found = found + 1
      end while found < ordinal
      return index
    end

    def cleaned
      user_agent = self.strip.dup
      user_agent.sub!('UP.Link', '')
      user_agent.replace($1) if user_agent =~ /^(.+)NOKIA-MSISDN\:\ (.+)$/i
      user_agent.sub!("'M', 'Y' 'P', 'H', 'O', 'N', 'E'", "MyPhone")
      user_agent.sub!('(null)', '')

      # remove serial numbers
      user_agent.sub!(/\/SN\d{15}/, '/SNXXXXXXXXXXXXXXX')
      user_agent.sub!(/\[(ST|TF|NT)\d+\]/, '')

      # remove locale identifiers
      user_agent.sub!(/([ ;])[a-zA-Z]{2}-[a-zA-Z]{2}([ ;\)])/, '\1xx-xx\2')

      pos = user_agent.index('BlackBerry')
      user_agent.replace(user_agent.slice(pos, user_agent.length-pos)) unless pos.nil?

      user_agent.sub!(/(Android \d\.\d)([^; \/\)]+)/, '\1')
      return user_agent
    end

    # guess the manufacturer of self
    def classify
      unless self.is_desktop_browser?
        return 'nokia' if self.contains('Nokia')
        return 'samsung' if self.contains(['Samsung/SGH', 'SAMSUNG-SGH']) || self.starts_with(['SEC-', 'Samsung', 'SAMSUNG', 'SPH', 'SGH', 'SCH']) || self.starts_with('samsung', true)
        return 'blackberry' if self.contains('blackberry', true) || self.contains('RIM')
        return 'sonyericsson' if self.contains('Sony')
        return 'motorola' if self.starts_with(['Mot-', 'MOT-', 'MOTO', 'moto']) || self.contains('Motorola')

        return 'alcatel' if self.starts_with('alcatel', true)
        return 'apple' if self.contains(['iPhone', 'iPod', 'iPad', '(iphone'])
        return 'benq' if self.starts_with('benq', true)
        return 'docomo' if self.starts_with('DoCoMo')
        return 'grundig' if self.starts_with('grundig', true)
        return 'htc' if self.contains(['HTC', 'XV6875'])
        return 'kddi' if self.contains('KDDI-')
        return 'kyocera' if self.starts_with(['kyocera', 'QC-', 'KWC-'])
        return 'lg' if self.starts_with('lg', true)
        return 'mitsubishi' if self.starts_with('Mitsu')
        return 'nec' if self.starts_with(['NEC-', 'KGT'])
        return 'nintendo' if self.contains('Nintendo') || (self.starts_with('Mozilla/') && self.starts_with('Nitro') && self.starts_with('Opera'))
        return 'panasonic' if self.contains('Panasonic')
        return 'pantech' if self.starts_with(['Pantech', 'PT-', 'PANTECH', 'PG-'])
        return 'philips' if self.starts_with('philips', true)
        return 'portalmmm' if self.starts_with('portalmmm')
        return 'qtek' if self.starts_with('Qtek')
        return 'sagem' if self.starts_with('sagem', true)
        return 'sharp' if self.starts_with('sharp', true)
        return 'siemens' if self.starts_with('SIE-')
        return 'spv' if self.starts_with('SPV') || (self.starts_with('Mozilla/') && self.contains('SPV'))
        return 'toshiba' if self.starts_with('Toshiba')
        return 'vodafone' if self.starts_with('Vodafone')

        # mobile browsers
        return 'android' if self.contains('Android')
        return 'operamini' if self.contains(['Opera Mini', 'Opera Mobi'])
        return 'windowsce' if self.contains('Mozilla/') && self.contains('Windows CE')
      end

      # Process Robots (Web Crawlers and the like)
      return 'bot' if self.is_robot?

      # Process NON-MOBILE user agents
      unless self.is_mobile_browser?
        return 'aol' if self.contains(['AOL', 'America Online']) || self.contains('aol 9', true)
        return 'msie' if self.starts_with('Mozilla') && self.contains('MSIE') && !self.contains(['Opera', 'armv', 'MOTO', 'BREW'])
        return 'firefox' if self.contains('Firefox') && !self.contains(['Sony', 'Novarra', 'Opera'])
        return 'chrome' if self.contains('Chrome') 
        return 'konqueror' if self.contains('Konqueror')
        return 'opera' if self.contains('Opera')
        return 'safari' if self.starts_with('Mozilla') && self.contains('Safari')
      end

      return 'catchall'
    end

    def self.classify(user_agent)
      self.new(user_agent).classify
    end
  end
end
