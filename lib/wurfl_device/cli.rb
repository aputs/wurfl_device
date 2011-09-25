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
      version
      WurflDevice.ui.info "http://github.com/aputs/wurfl_device for README"
      WurflDevice.ui.info ""
      super
    end

    desc "show DEVICE_ID|USER_AGENT", "display capabilities DEVICE_ID|USER_AGENT"
    method_option :json, :type => :boolean, :banner => "show the dump in json format", :aliases => "-j"
    method_option :yaml, :type => :boolean, :banner => "show the dump in yaml format", :default => true, :aliases => "-y"
    def show(device_id)
      device = WurflDevice.get_device(device_id)
      if device_id !~ /generic/i && !device.is_generic?
        device = WurflDevice.get_device_from_ua(device_id)
      end

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
        WurflDevice.clear_devices
      end
      WurflDevice.ui.info "updating wurfl devices cache."
      WurflDevice.initialize_cache
      WurflDevice.ui.info "rebuilding user_agents cache."
      WurflDevice.rebuild_user_agent_cache
      WurflDevice.ui.info "done."
    end

    desc "rebuild", "rebuild the existing user_agents cache"
    def rebuild
      WurflDevice.ui.info "rebuilding the user_agents cache."
      WurflDevice.rebuild_user_agent_cache
      WurflDevice.ui.info "done."
    end

    desc "info", "show wurfl_cache information"
    def info
      version
      WurflDevice.ui.info ""
      WurflDevice.ui.info "wurfl-xml version: " + WurflDevice.db.get("wurfl:version")
      #WurflDevice.ui.info "wurfl-xml last updated" + WurflDevice.db.get("wurfl:last_updated")
      WurflDevice.ui.info WurflDevice.commify(WurflDevice.db.hkeys("wurfl:user_agent_cache").length) + " user agents in cache"
    end

    desc "version", "show the wurfl_device version information"
    def version
      WurflDevice.ui.info "wurfl_device version #{WurflDevice::VERSION.freeze}"
    end
    map %w(-v --version) => :version
  end
end
