# encoding: utf-8
require 'thor'
require 'benchmark'
require 'wurfl_device'
require 'yaml'

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

    desc "webservice [start|stop|restart|status]", "start a wurfl_device server"
    method_option "base-dir", :type => :string, :banner => "set base directory for data files", :aliases => "-d", :default => WurflDevice::Settings::BASE_DIR
    method_option :host, :type => :string, :banner => "set webservice host", :aliases => "-h", :default => WurflDevice::Settings::WEBSERVICE_HOST
    method_option :port, :type => :numeric, :banner => "set webservice port", :aliases => "-p", :default => WurflDevice::Settings::WEBSERVICE_PORT
    method_option :worker, :type => :numeric, :banner => "set worker count", :aliases => "-w", :default => WurflDevice::Settings::WEBSERVICE_WORKER
    method_option :socket, :type => :string, :banner => "use unix domain socket", :aliases => "-s", :default => File.join(WurflDevice::Settings::BASE_DIR, WurflDevice::Settings::WEBSERVICE_SOCKET)
    method_option :socket_only, :type => :boolean, :banner => "start as unix domain socket listener only", :aliases => "-t", :default => false
    def webservice(action=nil)
      opts = options.dup

      action ||= 'status'

      pid_file = File.join(WurflDevice::Settings::BASE_DIR, WurflDevice::Settings::WEBSERVICE_PID)
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
        FileUtils.rm_f(pid_file)
      elsif action == 'restart'
        server('stop')
        sleep(0.3)
        server('start')
      else
        #status
      end
    end
    map %w(server) => :webservice

    desc "dump DEVICE_ID|USER_AGENT", "display capabilities DEVICE_ID|USER_AGENT"
    method_option :json, :type => :boolean, :banner => "show the dump in json format", :aliases => "-j"
    method_option :yaml, :type => :boolean, :banner => "show the dump in yaml format", :aliases => "-y"
    def dump(device_id)
      capabilities = WurflDevice.capabilities_from_id(device_id)
      capabilities = WurflDevice.capabilities_from_user_agent(device_id) if capabilities['id'].nil?

      if capabilities.nil?
        WurflDevice.ui.info "Nothing to dump"
      elsif options.json?
        WurflDevice.ui.info capabilities.to_json
      else
        WurflDevice.ui.info capabilities.to_yaml
      end
    end

    desc "list", "list user agent cache list"
    method_option "matched-only", :type => :boolean, :banner => "show user agents that were matched", :aliases => "-m"
    def list
      matched_only = options['matched-only']
      WurflDevice::Cache::UserAgents.entries.each do |user_agent|
        kv = WurflDevice::Cache::UserAgents.keys_values user_agent
        next if kv.count <= 1 && matched_only
        WurflDevice.ui.info "#{user_agent}:#{kv['id']}"
      end
    end

    desc "init [WURFL_XML_FILE]", "initialize the wurfl device cache"
    method_option :update, :type => :boolean, :banner => "don't clear previous cache", :aliases => "-u", :default => false
    def init(xml_file=nil)
      xml_file ||= Settings.default_wurfl_xml_file
      unless options.update?
        WurflDevice.ui.info "clearing existing device cache."
        WurflDevice::Cache.clear
      end
      WurflDevice.ui.info "initializing wurfl device cache."
      WurflDevice::Cache.initialize_cache(xml_file)
      status true
    end

    desc "status", "show wurfl cache information"
    def status(skip_version=false)
      version unless skip_version
      unless WurflDevice::Cache.initialized?
        WurflDevice.ui.info "cache is not initialized"
        return
      end
      WurflDevice.ui.info "cache info:"
      WurflDevice.ui.info "  wurfl-xml version: " + WurflDevice::Cache::Status.version.join(' ')
      WurflDevice.ui.info "  cache last updated: " + WurflDevice::Cache::Status.last_updated
      devices = WurflDevice::Cache::Devices.entries
      user_agents = WurflDevice::Cache::UserAgents.entries
      user_agents_message = ''
      user_agents_message = " (warning count should be greater than or equal to devices count)" if user_agents.length < devices.length 

      matched_count = 0
      WurflDevice::Cache::UserAgents.entries.each do |user_agent|
        kv = WurflDevice::Cache::UserAgents.keys_values user_agent
        next if kv.count == 1
        matched_count = matched_count + 1
      end
      WurflDevice.ui.info "  " + commify(devices.length) + " device id's"
      WurflDevice.ui.info "  " + commify(user_agents.length) + " exact user agents" + user_agents_message
      WurflDevice.ui.info "  " + commify(matched_count) + " user agents matched found in cache"

      user_agent_manufacturers = Array.new
      WurflDevice::Cache::UserAgentsManufacturers.entries.each do |index|
        user_agent_manufacturers << "#{index}(" + commify(WurflDevice::Cache::UserAgentsManufacturers.keys(index).length) + ")"
      end
      user_agent_manufacturers.sort!
      WurflDevice.ui.info "wurfl user agent manufacturers:"
      while !user_agent_manufacturers.empty?
        sub = user_agent_manufacturers.slice!(0, 7)
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
