# encoding: utf-8
require 'wurfl_device/version'

module WurflDevice
  autoload :Capability,         'wurfl_device/capability'
  autoload :Handset,            'wurfl_device/handset'
  autoload :UserAgent,          'wurfl_device/user_agent'

  GENERIC                       = 'generic'
  GENERIC_XHTML                 = 'generic_xhtml'
  GENERIC_WEB_BROWSER           = 'generic_web_browser'

  WORST_MATCH                   = 7

  class WurflDeviceError < StandardError
    def self.status_code(code = nil); define_method(:status_code) { code }; end
  end
  class CacheError    < WurflDeviceError; status_code(10); end
  class XMLFileError  < WurflDeviceError; status_code(11); end

  def self.default_wurfl_xml_file
    File.join(TMP_DIR, 'wurfl.xml')
  end
end

require 'wurfl_device/railtie' if defined?(Rails)
