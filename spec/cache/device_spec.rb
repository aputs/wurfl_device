require 'spec_helper'
require 'yaml'

describe WurflDevice do
  describe :devices do
    it "cache should be available" do
      WurflDevice.is_initialized?.should == true
    end

    it "generic device should exists" do
      device = WurflDevice.get_actual_device(WurflDevice::Constants::GENERIC)
      device.id.should == WurflDevice::Constants::GENERIC
    end

    it "check for user agent matcher" do
      user_agent = 'Mozilla/5.0 (SymbianOS/9.2; U; Series60/3.1 Nokia6120c/6.01; Profile/MIDP-2.0 Configuration/CLDC-1.1 ) AppleWebKit/413 (KHTML, like Gecko) Safari/413'
      device = WurflDevice.get_device_from_ua(user_agent)
      device.id.should == 'nokia_6120c_ver1_sub601'
    end
  end
end
