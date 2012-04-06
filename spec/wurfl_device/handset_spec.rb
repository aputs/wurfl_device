require 'spec_helper'

module WurflDevice
  describe Handset do
    before(:each) do
      Cache.storage.flushdb
      Cache.initialize_cache! File.join(File.dirname(__FILE__), '../faked_project/wurfl.xml')
    end

    it "can detect broken fall_back list" do
      lambda { Handset.new('broken_device_tree_id').fall_back_tree }.should raise_exception(CacheError)
    end

    it "can list proper fall_back tree count" do
      Handset.new('sonyericsson_k810_ver1').fall_back_tree.count.should == 6
    end

    it "can get capabilities from fall_back" do
      Handset.new('sonyericsson_k810_ver1').capabilities.canvas_support.should == 'none'
    end
  end
end