module WurflDevice
  class Capability
    class Group < Capability
    protected
      def get_value(name)
        return instance_variable_get(instance_v_name(name)) if instance_variable_defined?(instance_v_name(name))
        return nil
      end
    end

    # override ruby 1.9 Object#display method, since `display` is one of wurfl's capabilities
    def display(port=$>); get_value('display'); end

    def [](name)
      get_value(name)
    end

    def []=(name, value)
      instance_variable_set(instance_v_name(name), value)
    end

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
      return instance_variable_get(instance_v_name(name)) if instance_variable_defined?(instance_v_name(name))

      c_group = Cache::CapabilityList.capabilities[name]
      if c_group && (iv_group = instance_variable_get(instance_v_name(c_group)))
        return iv_group[name]
      end

      return nil
    end

    def instance_v_name(name)
      "@#{name.to_s}"
    end
  end
end