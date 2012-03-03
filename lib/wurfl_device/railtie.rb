# encoding: utf-8

module WurflDevice
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.expand_path('../..', File.dirname(__FILE__)), 'lib', 'tasks', 'wurfl.rake')
    end
  end
end
