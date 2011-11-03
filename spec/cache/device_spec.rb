require 'spec_helper'

describe WurflDevice do
  it "devices should be many" do
    WurflDevice::Cache::Devices.entries.count.should > 0
  end

  it "generic device should exists" do
    capabilities = WurflDevice.capabilities_from_id(WurflDevice::Settings::GENERIC)
    capabilities.id.nil?.should == false
    capabilities.id.should == WurflDevice::Settings::GENERIC
  end
end
