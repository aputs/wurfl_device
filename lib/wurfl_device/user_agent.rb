module WurflDevice
  class UserAgent < String
    def is_desktop_browser?
      ua = self.downcase
      WurflDevice::Constants::DESKTOP_BROWSERS.each do |sig|
        return true if ua.index(sig)
      end
      return false
    end

    def is_mobile_browser?
      ua = self.downcase
      return false if self.is_desktop_browser?
      return true if ua =~ /[^\d]\d{3}x\d{3}/
      WurflDevice::Constants::DESKTOP_BROWSERS.each do |sig|
        return true if ua.index(sig)
      end
      return false
    end

    def is_robot?
      ua = self.downcase
      WurflDevice::Constants::ROBOTS.each do |sig|
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
      user_agent = self.dup
      user_agent.sub!('UP.Link', '')
      user_agent.replace($1) if user_agent =~ /^(.+)NOKIA-MSISDN\:\ (.+)$/i
      user_agent.sub!("'M', 'Y' 'P', 'H', 'O', 'N', 'E'", "MyPhone")
      user_agent.sub!('(null)', '')

      # remove serial numbers
      user_agent.sub!(/\/SN\d{15}/, '/SNXXXXXXXXXXXXXXX')
      user_agent.sub!(/\[(ST|TF|NT)\d+\]/, '')

      # remove locale identifiers
      user_agent.sub!(/([ ;])[a-zA-Z]{2}-[a-zA-Z]{2}([ ;\)])/, '\1xx-xx\2')

      pos = self.index('BlackBerry')
      user_agent.replace(self.slice(pos, user_agent.length-pos)) unless pos.nil?

      user_agent.sub!(/(Android \d\.\d)([^; \/\)]+)/, '\1')
      user_agent.strip!
      user_agent
    end
  end
end
