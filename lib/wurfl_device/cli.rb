require 'thor'
require 'yaml'
require 'wurfl_device'

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

    desc "server [start|stop|restart|status]", "start a wurfl_device server"
    method_option "base-dir", :type => :string, :banner => "set base directory for data files", :aliases => "-d", :default => WurflDevice::Constants::WEBSERVICE_ROOT
    method_option :host, :type => :string, :banner => "set webservice host", :aliases => "-h", :default => WurflDevice::Constants::WEBSERVICE_HOST
    method_option :port, :type => :numeric, :banner => "set webservice port", :aliases => "-p", :default => WurflDevice::Constants::WEBSERVICE_PORT
    method_option :socket, :type => :string, :banner => "use unix domain socket", :aliases => "-s", :default => File.join(WurflDevice::Constants::WEBSERVICE_ROOT, WurflDevice::Constants::WEBSERVICE_SOCKET)
    method_option :socket_only, :type => :boolean, :banner => "start as unix domain socket listener only", :aliases => "-t", :default => false
    def server(action=nil)
      opts = options.dup

      action ||= 'status'

      pid_file = File.join(WurflDevice::Constants::WEBSERVICE_ROOT, WurflDevice::Constants::WEBSERVICE_PID)
      base_dir = opts['base-dir']

      FileUtils.mkdir_p(base_dir) unless File.directory?(base_dir)
      FileUtils.cd(File.expand_path('../../', File.dirname(__FILE__)))
      if action == 'start'
        unless File.exists?(pid_file)
          WurflDevice.ui.info "starting webservice..."
          WurflDevice.ui.info "listening at #{opts.socket}"
          args = [
            File.join(RbConfig::CONFIG['bindir'], RbConfig::CONFIG['ruby_install_name']),
            '-S',
            'unicorn',
            '-E',
            'production',
            '-D',
            '-c',
            File.expand_path('../../config/unicorn.conf.rb', File.dirname(__FILE__)),
            ]

          unless opts.socket_only?
            WurflDevice.ui.info "listening at #{opts.host}:#{opts.port}"
            args << '-o'
            args << opts.host
            args << '-p'
            args << opts.port
          end

          system(args.join(' '))
        end
      elsif action == 'stop'
        if File.exists?(pid_file)
          WurflDevice.ui.info "stopping webservice..."
          args = [
            'kill',
            '-QUIT',
            "`cat #{pid_file}`",
            ]

          system(args.join(' '))
        end
      elsif action == 'restart'
        server('stop')
        server('start')
      else
        #status
      end
    end

    desc "dump DEVICE_ID|USER_AGENT", "display capabilities DEVICE_ID|USER_AGENT"
    method_option :json, :type => :boolean, :banner => "show the dump in json format", :aliases => "-j"
    method_option :yaml, :type => :boolean, :banner => "show the dump in yaml format", :aliases => "-y"
    def dump(device_id)
      device = WurflDevice.get_device_from_id(device_id)
      device = WurflDevice.get_device_from_ua(device_id) if device.nil?

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
        device_id = device.id || ''
        user_agent ||= ''
        WurflDevice.ui.info user_agent + ":" + device_id
      end
    end

    desc "update", "update the wurfl cache"
    method_option "clear-all", :type => :boolean, :banner => "remove all wurfl cache related"
    method_option "clear-dev", :type => :boolean, :banner => "clear the device cache first before updating"
    method_option "clear-ua", :type => :boolean, :banner => "remove all wurfl user agents cache"
    def update
      opts = options.dup
      if opts['clear-all']
        WurflDevice.ui.info "clearing all cache entries."
        WurflDevice.clear_devices
        WurflDevice.clear_cache
      end
      if opts['clear-ua']
        WurflDevice.ui.info "clearing user agent cache."
        WurflDevice.clear_user_agent_cache
      end
      if opts['clear-dev']
        WurflDevice.ui.info "clearing device cache."
        WurflDevice.clear_devices
      end
      WurflDevice.ui.info "updating wurfl devices cache."
      WurflDevice.initialize_cache
      WurflDevice.ui.info "rebuilding cache."
      WurflDevice.rebuild_user_agent_cache
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
      indexes = Array.new
      WurflDevice.get_indexes.each do |index|
        index.gsub!(WurflDevice::Constants::WURFL_DEVICES_INDEX, '')
        indexes << "#{index}(" + commify(WurflDevice.get_user_agents_in_index(index).length) + ")"
      end
      indexes.sort!
      WurflDevice.ui.info "wurfl user agent indexes:"
      while !indexes.empty?
        sub = indexes.slice!(0, 7)
        WurflDevice.ui.info "  " + sub.join(', ')
      end
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
