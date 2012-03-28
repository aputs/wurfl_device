require 'spec_helper'

module WurflDevice
  describe Cache do
    context "initialization" do
      before(:each) do
        @xml_file = '/tmp/wurfl.xml'
      end

      it "initialize the cache" do
        Cache.initialize_cache!(@xml_file)
        Cache.valid?.should be(true)
      end
    end
  end
end