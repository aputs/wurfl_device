require 'spec_helper'

module WurflDevice
  describe Handset do
    context "capabilities" do
      before(:each) do
        WurflDevice.configure do
          config.xml_file = File.join(File.dirname(__FILE__), '../faked_project/wurfl.xml')
          config.redis_db = 2
          Cache.storage.flushdb
          initialize_cache!
        end
      end

      it "can detect broken fall_back list" do
        lambda { Handset.new('broken_device_tree_id').fall_back_tree }.should raise_exception(CacheError)
      end

      it "can list proper fall_back tree count" do
        Handset.new('sonyericsson_k810_ver1').fall_back_tree.count.should == 7
      end

      it "can get capability from full capabilities list" do
        Handset.new('sonyericsson_k810_ver1').full_capabilities.canvas_support.should == 'none'
      end

      it "can get capabilities from fallback chain" do
#        Handset.new('sonyericsson_k810_ver1').capabilities.canvas_support.should == 'none'
      end
    end
  end
end