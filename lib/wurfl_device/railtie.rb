# encoding: utf-8

module WurflDevice
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.expand_path('../..', File.dirname(__FILE__)), 'rakelib', 'wurfl_device.rake')
    end
  end
end
