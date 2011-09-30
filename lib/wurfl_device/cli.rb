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

    desc "dump DEVICE_ID|USER_AGENT", "display capabilities DEVICE_ID|USER_AGENT"
    method_option :json, :type => :boolean, :banner => "show the dump in json format", :aliases => "-j"
    method_option :yaml, :type => :boolean, :banner => "show the dump in yaml format", :aliases => "-y"
    def dump(device_id)
      device = WurflDevice.get_device_from_id(device_id)
      device = WurflDevice.get_device_from_ua(device_id, use_cache) if device.nil?

      if options.json?
        WurflDevice.ui.info device.capabilities.to_json
      else
        WurflDevice.ui.info device.capabilities.to_yaml
      end
    end

    desc "list", "list user agent cache list"
    def list
      WurflDevice.get_user_agents_in_cache.each do |user_agent|
        device = WurflDevice.get_device_from_ua_cache(user_agent)
        device_id = ''
        device_id = device.id unless device.nil?
        WurflDevice.ui.info user_agent + ":" + device_id
      end
    end

    desc "update", "update the wurfl cache"
    method_option "clear-all", :type => :boolean, :banner => "remove all wurfl cache related"
    method_option "clear-dev", :type => :boolean, :banner => "clear the device cache first before updating"
    method_option "clear-ua", :type => :boolean, :banner => "remove all wurfl user agents cache"
    method_option "rebuild", :type => :boolean, :banner => "rebuild the user agent cache after updating"
    def update
      opts = options.dup
      if opts['clear-all']
        WurflDevice.ui.info "clearing all cache entries."
        WurflDevice.clear_devices
        WurflDevice.clear_cache
        opts['rebuild'] = true
      end
      if opts['clear-ua']
        WurflDevice.ui.info "clearing user agent cache."
        WurflDevice.clear_user_agent_cache
      end
      if opts['clear-dev']
        WurflDevice.ui.info "clearing device cache."
        WurflDevice.clear_devices
        opts['rebuild'] = true
      end
      WurflDevice.ui.info "updating wurfl devices cache."
      WurflDevice.initialize_cache
      if opts.rebuild?
        WurflDevice.ui.info "rebuilding cache."
        WurflDevice.rebuild_user_agent_cache
      end
      WurflDevice.ui.info "done."
      WurflDevice.ui.info ""
      status true
    end

    desc "rebuild", "rebuild the existing user_agents cache"
    def rebuild
      WurflDevice.ui.info "rebuilding the user_agents cache."
      WurflDevice.rebuild_user_agent_cache
      WurflDevice.ui.info "done."
    end

    desc "status", "show wurfl cache information"
    def status(skip_version=false)
      version unless skip_version
      unless WurflDevice.is_initialized?
        WurflDevice.ui.info "cache is not initialized"
        return
      end
      info = WurflDevice.get_info
      version = info['version'] || 'none'
      last_update = info['last_updated'] || 'unknown'
      WurflDevice.ui.info "cache info:"
      WurflDevice.ui.info "  wurfl-xml version: " + version
      WurflDevice.ui.info "  cache last updated: " + last_update
      devices = WurflDevice.get_devices
      user_agents = WurflDevice.get_user_agents
      user_agents_message = ''
      user_agents_message = " (warning count should be equal to devices count)" if devices.length != user_agents.length
      WurflDevice.ui.info "  " + commify(devices.length) + " device id's"
      WurflDevice.ui.info "  " + commify(user_agents.length) + " exact user agents" + user_agents_message
      WurflDevice.ui.info "  " + commify(WurflDevice.get_user_agents_in_cache.length) + " user agents found in cache"
      WurflDevice.ui.info ""
    end
    map %w(stats stat info) => :status

    desc "version", "show the wurfl_device version information"
    def version
      WurflDevice.ui.info "wurfl_device version #{WurflDevice::VERSION.freeze}"
    end
    map %w(-v --version) => :version
  private
    def commify(n)
      n.to_s =~ /([^\.]*)(\..*)?/
      int, dec = $1.reverse, $2 ? $2 : ""
      while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
      end
      int.reverse + dec
    end
  end
end
