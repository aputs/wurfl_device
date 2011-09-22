require 'thor'
require 'yaml'
require 'json'

module WurflDevice
  class CLI < Thor
    include Thor::Actions

    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      WurflDevice.ui = UI::Shell.new(the_shell)
      WurflDevice.ui.debug! if options["verbose"]
    end

    check_unknown_options!

    default_task :help

    desc "help", "Show this message"
    def help(cli=nil)
      WurflDevice.ui.info "#{$0} v#{WurflDevice::VERSION.freeze}\n\n"
      super
      WurflDevice.ui.info "http://github.com/aputs/wurfl_device for README"
    end

    desc "show DEVICE_ID|USER_AGENT", "display capabilities DEVICE_ID|USER_AGENT"
    method_option :json, :type => :boolean, :banner => "show the dump in json format", :aliases => "-j"
    method_option :yaml, :type => :boolean, :banner => "show the dump in yaml format", :default => true, :aliases => "-y"
    def show(device_id)
      device = WurflDevice.get_device(device_id)
      if options.json?
        WurflDevice.ui.info device.capabilities.to_json
      elsif options.yaml?
        WurflDevice.ui.info device.capabilities.to_yaml
      end
    end

    desc "update", "update the wurfl cache"
    method_option "clear", :type => :boolean, :banner => "clear the device cache first before updating"
    def update
      if options.clear?
        WurflDevice.ui.info "clearing device cache."
        Device.clear_cache
      end
      WurflDevice.ui.info "Updating wurfl devices cache."
      Device.initialize_cache
      WurflDevice.ui.info "done."
    end

    desc "version", "Prints the wurfl_device version information"
    def version
      WurflDevice.ui.info "wurfl_device version #{WurflDevice::VERSION.freeze}"
    end
    map %w(-v --version) => :version
  end
end
