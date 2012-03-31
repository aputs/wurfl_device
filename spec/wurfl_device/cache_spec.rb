require 'spec_helper'

module WurflDevice
  describe Cache do
    context "initialization" do
      it { should initialize_cache_from(File.join(File.dirname(__FILE__), '../faked_project/wurfl.xml')) }
      it { should handset(GENERIC).exists? }
      it { should handset(GENERIC_XHTML).exists? }
      it { should handset(GENERIC_WEB_BROWSER).exists? }
    end
  end
end