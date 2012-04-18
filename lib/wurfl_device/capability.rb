module WurflDevice
  class Capability < ::Hash
    def display(port=$>); self['display']; end

  protected
    def method_missing(method, *args, &block)
      method = method.to_s
      result = nil
      if method =~ /^(\w+)\?$/
        if args.empty?
          result = (!!get_value($1))
        else
          result = (get_value($1) == args.first)
        end
      else
        result = get_value(method)
      end
      raise CapabilityError, "unknown capability `#{method}`" if result.nil?
      result
    end

    def get_value(name)
      return self[name] if self[name]

      if c_group = Cache::CapabilityList.capabilities[name]
        return self[c_group][name]
      end

      return nil
    end
  end
end