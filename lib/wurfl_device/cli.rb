# encoding: utf-8
require 'thor'
require 'benchmark'
require 'wurfl_device'
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
      if matched_only
        Cache::UserAgentsMatched.entries.each do |user_agent|
          capabilities = WurflDevice.capabilities_from_user_agent(user_agent)
          WurflDevice.ui.info "#{user_agent}:#{capabilities.id}"
        end
      else
        Cache::UserAgents.entries.each do |user_agent|
          device_id = Cache::UserAgents.get(user_agent)
          WurflDevice.ui.info "#{user_agent}:#{device_id}"
        end
      end
    end

    desc "init [WURFL_XML_FILE]", "initialize the wurfl device cache"
    method_option :update, :type => :boolean, :banner => "don't clear previous cache", :aliases => "-u", :default => false
    def init(xml_file=nil)
      xml_file ||= Settings.default_wurfl_xml_file
      unless options.update?
        WurflDevice.ui.info "clearing existing device cache."
        Cache.clear
      end
      WurflDevice.ui.info "initializing wurfl device cache."
      Cache.initialize_cache(xml_file)

      if options.update?
        WurflDevice.ui.info "rebuilding user agent cache."
        Cache.rebuild_user_agents
      end

      status true
    end

    desc "status", "show wurfl cache information"
    def status(skip_version=false)
      version unless skip_version
      unless Cache.initialized?
        WurflDevice.ui.info "cache is not initialized"
        return
      end
      WurflDevice.ui.info "cache info:"
      WurflDevice.ui.info "  wurfl-xml version: " + Cache::Status.version.join(' ')
      WurflDevice.ui.info "  cache last updated: " + Cache::Status.last_updated
      devices = Cache::Devices.entries
      user_agents = Cache::UserAgents.entries
      user_agents_message = ''
      user_agents_message = " (warning count should be greater than or equal to devices count)" if user_agents.length < devices.length 

      WurflDevice.ui.info "  " + commify(devices.length) + " device id's"
      WurflDevice.ui.info "  " + commify(user_agents.length) + " user agents in cache" + user_agents_message
      WurflDevice.ui.info "  " + commify(Cache::UserAgentsMatched.entries.count) + " user agents matched"

      user_agent_manufacturers = Array.new
      Cache::UserAgentsManufacturers.entries.each do |index|
        user_agent_manufacturers << "#{index}(" + commify(Cache::UserAgentsManufacturers.hkeys(index).length) + ")"
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
      WurflDevice.ui.info "wurfl_device version #{VERSION.freeze}"
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
