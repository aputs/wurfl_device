# encoding: utf-8
require 'thor'
require 'benchmark'
require 'wurfl_device'
require 'wurfl_device/ui'
require 'yaml'
require 'json'

module WurflDevice
  class << self
    attr_writer :ui

    def ui
      @ui ||= UI.new
    end
  end

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
    def dump(device_id_user_agent)
      handset = WurflDevice.handset_from_device_id(device_id_user_agent)
      handset = WurflDevice.handset_from_user_agent(device_id_user_agent) unless handset

      if handset.nil?
        WurflDevice.ui.info "Nothing to dump"
      elsif options.json?
        WurflDevice.ui.info handset.full_capabilities.to_json
      else
        WurflDevice.ui.info handset.full_capabilities.to_yaml
      end
    end

    desc "list", "list user agent cache list"
    method_option "matched-only", :type => :boolean, :default => false, :banner => "show user agents that were matched", :aliases => "-m"
    def list
      only_matched = options['matched-only']
      WurflDevice::Cache::UserAgentsMatchers.user_agent_matched.each { |user_agent, handset_id| WurflDevice.ui.info "#{handset_id} : #{user_agent}" } if only_matched
      WurflDevice::Cache::HandsetsList.handsets_and_user_agents.each { |user_agent, handset_id| WurflDevice.ui.info "#{handset_id} : #{user_agent}" } unless only_matched
    end

    desc "init [WURFL_XML_FILE]", "initialize the wurfl device cache"
    def init(xml_file=nil)
      WurflDevice.configure do
        config.xml_file = xml_file if xml_file
        initialize_cache!
      end

      WurflDevice.ui.info "cache initialized!"
      WurflDevice.ui.info ""
      status true
    end

    desc "status", "show wurfl cache information"
    def status(skip_version=false)
      version unless skip_version
      unless WurflDevice::Cache.valid?
        WurflDevice.ui.info "cache is not initialized"
        return
      end
      WurflDevice.ui.info "cache info:"
      WurflDevice.ui.info "  cache last updated: " + WurflDevice::Cache.last_updated
      user_agents_message = ''
      actual_handset_count = WurflDevice::Cache::HandsetsList.handsets_and_user_agents.select { |d, h| Handset.new(h).actual_device_root? }.count
      actual_user_agents_count = WurflDevice::Cache::HandsetsList.handsets_and_user_agents.select { |u, h| u !~ /DO_NOT_MATCH/ }.count

      WurflDevice.ui.info "  " + commify(WurflDevice::Cache::HandsetsList.handsets_and_user_agents.values.count) + " handset id's (" + commify(actual_handset_count) + " actual device)"
      WurflDevice.ui.info "  " + commify(WurflDevice::Cache::HandsetsList.handsets_and_user_agents.keys.count) + " user agents in cache (" + commify(actual_user_agents_count) + " matchable)"
      WurflDevice.ui.info "  " + commify(WurflDevice::Cache::UserAgentsMatchers.user_agent_matched.count) + " user agents in matched cache"

      user_agent_manufacturers = WurflDevice::Cache::UserAgentsMatchers.user_agent_matchers.each_with_object([]) { |b, a| a << "#{b}(" + commify(WurflDevice::Cache::UserAgentsMatchers.user_agents_for_brand(b).count) + ")" }.sort
      WurflDevice.ui.info "wurfl user agent matchers(brands):"
      while !user_agent_manufacturers.empty?
        sub = user_agent_manufacturers.slice!(0, 7)
        WurflDevice.ui.info "  " + sub.join(', ')
      end
      WurflDevice.ui.info ""
    end
    map %w(stats stat info) => :status

    desc "version", "show the wurfl_device version information"
    def version(args=nil)
      WurflDevice.ui.info "wurfl_device version #{VERSION.freeze}"
    end
    map %w(--version) => :version

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
