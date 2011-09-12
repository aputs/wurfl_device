# -*- encoding: utf-8 -*-

require "wurfl_device/version"

module WurflDevice
  autoload :UI,       'wurfl_device/ui'

  class WurflDeviceError < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end

  class << self
    attr_writer :ui

    def ui
      @ui ||= UI.new
    end
  end
end