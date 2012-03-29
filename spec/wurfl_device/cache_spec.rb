require 'spec_helper'

module WurflDevice
  describe Cache do
    context "initialization" do
      before(:each) do
        @xml_file = File.join(File.dirname(__FILE__), '../faked_project/wurfl.xml')
      end

      it "initialize the cache" do
        Cache.initialize_cache!(@xml_file)
        Cache.valid?.should be(true)
      end
    end
  end
end