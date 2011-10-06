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
      {
        'nokia_x3_02_ver1' => 'NokiaX3-02/5.0 (05.60) Profile/MIDP-2.1 Configuration/CLDC-1.1',
        'nokia_n90_ver1_sub2052414' => 'NokiaN90-1/3.0541.5.2 Series60/2.8 Profile/MIDP-2.0 Configuration/CLDC-1.1',

        #'opwv_v6_generic' => 'SAMSUNG-B5712C/1.0 RTK-E/1.0 DF/1.0 Release/08.17.2007 Browser/Openwave6.2.3.3.c.1.101 Profile/MIDP-2.0 Configuration/CLDC-1.1/*MzU3ODEwMDIwNzc5ODgx UP.Browser/6.',
        'samsung_a707_ver1_subshpvppr5' => 'SAMSUNG-SGH-A707/1.0 SHP/VPP/R5 NetFront/3.3 SMM-MMS/1.2.0 profile/MIDP-2.0 configuration/CLDC-1.1',
        'samsung_u700_ver1_subua' => 'SAMSUNG-SGH-U700/1.0 SHP/VPP/R5 NetFront/3.4 SMM-MMS/1.2.0 profile/MIDP-2.0 configuration/CLDC-1.1',
        #'generic' => 'SAMSUNG-SCH-M710/(null)ID4 (compatible; MSIE 6.0; Windows CE; PPC) Opera 9.5',

        'sonyericsson_k700i_ver1subr2ay' => 'SonyEricssonK700i/R2AC SEMC-Browser/4.0.2 Profile/MIDP-2.0 Configuration/CLDC-1.1',
        'sonyericsson_k550i_ver1_subr1jd' => 'SonyEricssonK550i/R1JD Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1',

        'blackberry8520_ver1_subos5' => 'BlackBerry8520/5.0.0.592 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/603',

        'te' => "'M', 'Y' 'P', 'H', 'O', 'N', 'E' Browser/WAP2.0 Profile/MIDP-2.0 Configuration/CLDC-1.1",
      }.each_pair do |device_id, user_agent|
        device = WurflDevice.get_device_from_ua(user_agent)
        device.id.should == device_id
      end
    end
  end
end
