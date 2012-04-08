require 'spec_helper'
require 'fakeredis' unless ENV['NOFAKEREDIS']

module WurflDevice
  describe Cache do
    context "initialization" do
      before(:each) do
        WurflDevice.configure do
          config.xml_file = File.join(File.dirname(__FILE__), '../faked_project/wurfl.xml')
        end
      end
      it { should initialize_cache }
      it { should handset_count.not_empty? }
      it { should handset(GENERIC).exists? }
      it { should handset(GENERIC_XHTML).exists? }
      it { should handset(GENERIC_WEB_BROWSER).exists? }
    end
  end
end