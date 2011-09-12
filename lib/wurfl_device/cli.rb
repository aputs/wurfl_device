require 'thor'
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

    desc "help", "Show this message"
    def help(cli=nil)
      WurflDevice.ui.info "\n\n"
      super
      WurflDevice.ui.info "\ngit://github.com/aputs/wurfl_device.git for README"
    end

  end
end
