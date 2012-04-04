require 'spec_helper'

module WurflDevice
  describe Handset do
    before(:each) do
      Cache.storage.flushdb
      Cache.initialize_cache! File.join(File.dirname(__FILE__), '../faked_project/wurfl.xml')
    end

    it "can be stored" do
      handset = Handset.new('handset_id_to_store')
      #handset.capabilities.user_agent = ''
    end
  end
end