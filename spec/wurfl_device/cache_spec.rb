require 'spec_helper'

module WurflDevice
  describe Cache do
    context "initialization" do
      before(:each) do
        WurflDevice.configure do
          config.xml_file = File.join(File.dirname(__FILE__), '../faked_project/wurfl.xml')
          config.redis_db = 2
          Cache.storage.flushdb
          initialize_cache!
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