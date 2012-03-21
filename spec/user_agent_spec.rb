# encoding: utf-8
require 'spec_helper'

module WurflDevice
  describe UserAgent do
    before(:each) do
      @mobile_user_agent = "NokiaX3-02/5.0 (05.60) Profile/MIDP-2.1 Configuration/CLDC-1.1"
      @desktop_user_agent = "Mozilla/6.0 (Macintosh; I; Intel Mac OS X 11_7_9; de-LI; rv:1.9b4) Gecko/2012010317 Firefox/10.0a4"
      @robot_user_agent = "( Robots.txt Validator http://www.searchengineworld.com/cgi-bin/robotcheck.cgi )"
    end

    it "is encoded in UTF-8" do
      UserAgent.new().should be_encoded_as("UTF-8")
    end

    it "safely parses non UTF-8" do
      UserAgent.new(File.read(File.join(File.dirname(__FILE__), 'user_agent_with_invalid_encoding.txt'))).should be_encoded_as("UTF-8")
    end

    it ".is_desktop_browser?" do
      UserAgent.new(@desktop_user_agent).is_desktop_browser?.should be(true)
      UserAgent.new(@mobile_user_agent).is_desktop_browser?.should be(false)
    end

    it ".is_mobile_browser?" do
      UserAgent.new(@desktop_user_agent).is_mobile_browser?.should be(false)
      UserAgent.new(@mobile_user_agent).is_mobile_browser?.should be(true)
    end

    it ".is_robot?" do
      UserAgent.new(@robot_user_agent).is_robot?.should be(true)
      UserAgent.new(@mobile_user_agent).is_robot?.should be(false)
      UserAgent.new(@desktop_user_agent).is_robot?.should be(false)
    end

    it ".classify" do
      {
        'Nokia'         => 'Nokia6300/2.0 (05.50) Profile/MIDP-2.0 Configuration/CLDC-1.1 (botmobi http://find.mobi/bot.html abuse@mtld.mobi)',
        'Samsung'       => 'SAMSUNG-SGH-E200/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 UP.Browser/6.2.3.3.c.1.101 (GUI) MMP/2.0',
        'BlackBerry'    => 'Mozilla/5.0 (PlayBook; U; RIM Tablet OS 1.0.0; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/0.0.1 Safari/534.8+',
        'BlackBerry'    => 'Mozilla/5.0 (BlackBerry; U; BlackBerry AAAA; en-US) AppleWebKit/534.11+ (KHTML, like Gecko) Version/X.X.X.X Mobile Safari/534.11+',
        'SonyEricsson'  => 'SonyEricssonK700i/R2AG SEMC-Browser/4.0.3 Profile/MIDP-2.0 Configuration/CLDC-1.1',
        'Motorola'      => 'MOT-2100./11.03 UP.Browser/4.1.24f',
        'Alcatel'       => 'Alcatel-BF3/1.0 UP.Browser/4.1.23a',
        'Apple'         => 'Mozilla/5.0 (iPhone; U; CPU iOS 2_0 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/XXXXX Safari/525.20',
        'BenQ'          => 'BenQ-S500',
        'DoCoMo'        => 'DoCoMo/1.0/D501i',
        'Grundig'       => 'Grundig M131',
        'HTC'           => 'XV6875 Opera/9.50 (Windows NT 5.1; U; en)',
        'Kddi'          => 'KDDI-SA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0',
        'Kyocera'       => 'KWC-K127/1002 UP.Browser/6.2.3.9.g.1.110 (GUI) MMP/2.0',
        'LG'            => 'LG-GC900/V10a Obigo/WAP2.0 Profile/MIDP-2.1 Configuration/CLDC-1.1',
        'Mitsubishi'    => 'Mitsu/1.3.A (M750)',
        'Nec'           => 'NEC-N840',
        'Nintendo'      => 'Opera/9.50 (Nintendo DSi; Opera/483; U; en-US)',
        'Panasonic'     => 'Panasonic-VS3/#Vodafone/1.0/Panasonic-VS3',
        'Pantech'       => 'PANTECH-C520/R01 Browser/Obigo/Q05A Profile/MIDP-2.0 Configuration/CLDC-1.1',
        'Philips'       => 'Philips X710/MTK 6229.07B 08.12/WAP-2.0/MIDP-2.0/CLDC-1.1',
        'Portalmmm'     => 'portalmmm/1.0 m21i-10(c10)',
        'Qtek'          => 'Qtek S200',
        'Sagem'         => 'SAGEM-myZ-55/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Browser/6.2.3.3.g.2.101 (GUI) MMP/2.0',
        'Sharp'         => 'SHARP-TQ-GZ100S',
        'Siemens'       => 'SIE-S35/1.0 UP/4.1.8c',
        'SPV'           => 'Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320; SPV M600; OpVer 13.10.2.112)',
        'Toshiba'       => 'Toshiba VM-4050',
        'Vodafone'      => 'Vodafone/1.0/880SH/1.104 Browser/VF-NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1',
        'Android'       => 'Mozilla/5.0 (Linux; U; Android 2.2; es-es; GT-P1000 Build/FROYO) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
        'OperaMini'     => 'Opera/9.80 (J2ME/MIDP; Opera Mini/9.80 (S60; SymbOS; Opera Mobi/23.348; U; en) Presto/2.5.25 Version/10.54',
        'WindowsCE'     => 'Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320)',
        'Bot'           => 'Bjaaland',
        'MSIE'          => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
        'Firefox'       => 'Mozilla/6.0 (Macintosh; I; Intel Mac OS X 11_7_9; de-LI; rv:1.9b4) Gecko/2012010317 Firefox/10.0a4',
        'Chrome'        => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/535.20 (KHTML, like Gecko) Chrome/19.0.1036.7 Safari/535.20',
        'Konqueror'     => 'Mozilla/5.0 (compatible; Konqueror/4.5; FreeBSD) KHTML/4.5.4 (like Gecko)',
        'Opera'         => 'Opera/9.80 (Windows NT 6.1; U; es-ES) Presto/2.9.181 Version/12.00',
        'Safari'        => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; de-at) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1',
        'AOL'           => 'Mozilla/4.0 (compatible; MSIE 8.0; AOL 9.7; AOLBuild 4343.27; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)',
        'CatchAll'      => 'test',
      }.each_pair { |k, ua| UserAgent.new(ua).classify.should == k }
    end
  end
end

