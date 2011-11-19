module WurflDevice
  class Capability < ::Hash
    def initialize(hash={})
      super()
      hash.each do |key, value|
        if value.kind_of?(Hash)
          self[convert_key(key)] = Capability.new(value)
        else
          self[convert_key(key)] = value
        end
      end
    end

    def [](key)
      super(convert_key(key))
    end

    def []=(key, value)
      super(convert_key(key), value)
    end

    def delete(key)
      super(convert_key(key))
    end

    def values_at(*indices)
      indices.collect { |key| self[convert_key(key)] }
    end

    def merge(other)
      dup.merge!(other)
    end

    def merge!(other)
      other.each do |key, value|
        self[convert_key(key)] = value
      end
      self
    end

  protected
    def get_value(name)
      return self[name] if self.key?(name)
      if Settings::CAPABILITY_TO_GROUP.key?(name)
        capability_group = Settings::CAPABILITY_TO_GROUP[name]
        return self[capability_group][name] if self.key?(capability_group)
      end
      return nil
    end

    def convert_key(key)
      key.is_a?(Symbol) ? key.to_s : key
    end

    # Magic predicates. For instance:
    #
    #   capability.force?                   # => !!options['force']
    #   capability.shebang                  # => "/usr/lib/local/ruby"
    #   capability.test_framework?(:rspec)  # => options[:test_framework] == :rspec
    #
    # need to rewrite this for deep hash entries
    # use capability to group mapping
    def method_missing(method, *args, &block)
      method = method.to_s
      if method =~ /^(\w+)\?$/
        if args.empty?
          !!get_value($1)
        else
          get_value($1) == args.first
        end
      else
        get_value(method)
      end
    end
  end
end
