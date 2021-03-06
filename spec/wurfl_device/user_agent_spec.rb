# encoding: UTF-8
require 'spec_helper'

module WurflDevice
  describe UserAgent do
    context "unicode support" do
      it { should encoded('generic').as('UTF-8') }
      it { should encoded('NokiaX3-02/5.0 (05.60) Profile/MIDP-2.1 Configuration/CLDC-1.1ésumé').as('UTF-8') }
    end

    context "platform checker" do
      it { should platform('Mozilla/6.0 (Macintosh; I; Intel Mac OS X 11_7_9; de-LI; rv:1.9b4) Gecko/2012010317 Firefox/10.0a4').is_desktop }
      it { should platform('NokiaX3-02/5.0 (05.60) Profile/MIDP-2.1 Configuration/CLDC-1.1').is_mobile }
      it { should platform('( Robots.txt Validator http://www.searchengineworld.com/cgi-bin/robotcheck.cgi )').is_robot }
    end

    context "classify according to manufacturer" do
      it { should classify('Nokia6300/2.0 (05.50) Profile/MIDP-2.0 Configuration/CLDC-1.1 (botmobi http://find.mobi/bot.html abuse@mtld.mobi)').as('nokia') }
      it { should classify('SAMSUNG-SGH-E200/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 UP.Browser/6.2.3.3.c.1.101 (GUI) MMP/2.0').as('samsung') }
      it { should classify('Mozilla/5.0 (PlayBook; U; RIM Tablet OS 1.0.0; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/0.0.1 Safari/534.8+').as('blackberry') }
      it { should classify('Mozilla/5.0 (BlackBerry; U; BlackBerry AAAA; en-US) AppleWebKit/534.11+ (KHTML, like Gecko) Version/X.X.X.X Mobile Safari/534.11+').as('blackberry') }
      it { should classify('SonyEricssonK700i/R2AG SEMC-Browser/4.0.3 Profile/MIDP-2.0 Configuration/CLDC-1.1').as('sonyericsson') }
      it { should classify('MOT-2100./11.03 UP.Browser/4.1.24f').as('motorola') }
      it { should classify('Alcatel-BF3/1.0 UP.Browser/4.1.23a').as('alcatel') }
      it { should classify('Mozilla/5.0 (iPhone; U; CPU iOS 2_0 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/XXXXX Safari/525.20').as('apple') }
      it { should classify('BenQ-S500').as('benq') }
      it { should classify('DoCoMo/1.0/D501i').as('docomo') }
      it { should classify('Grundig M131').as('grundig') }
      it { should classify('XV6875 Opera/9.50 (Windows NT 5.1; U; en)').as('htc') }
      it { should classify('KDDI-SA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0').as('kddi') }
      it { should classify('KWC-K127/1002 UP.Browser/6.2.3.9.g.1.110 (GUI) MMP/2.0').as('kyocera') }
      it { should classify('LG-GC900/V10a Obigo/WAP2.0 Profile/MIDP-2.1 Configuration/CLDC-1.1').as('lg') }
      it { should classify('Mitsu/1.3.A (M750)').as('mitsubishi') }
      it { should classify('NEC-N840').as('nec') }
      it { should classify('Opera/9.50 (Nintendo DSi; Opera/483; U; en-US)').as('nintendo') }
      it { should classify('Panasonic-VS3/#Vodafone/1.0/Panasonic-VS3').as('panasonic') }
      it { should classify('PANTECH-C520/R01 Browser/Obigo/Q05A Profile/MIDP-2.0 Configuration/CLDC-1.1').as('pantech') }
      it { should classify('Philips X710/MTK 6229.07B 08.12/WAP-2.0/MIDP-2.0/CLDC-1.1').as('philips') }
      it { should classify('portalmmm/1.0 m21i-10(c10)').as('portalmmm') }
      it { should classify('Qtek S200').as('qtek') }
      it { should classify('SAGEM-myZ-55/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.0 UP.Browser/6.2.3.3.g.2.101 (GUI) MMP/2.0').as('sagem') }
      it { should classify('SHARP-TQ-GZ100S').as('sharp') }
      it { should classify('SIE-S35/1.0 UP/4.1.8c').as('siemens') }
      it { should classify('Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320; SPV M600; OpVer 13.10.2.112)').as('spv') }
      it { should classify('Toshiba VM-4050').as('toshiba') }
      it { should classify('Vodafone/1.0/880SH/1.104 Browser/VF-NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1').as('vodafone') }
      it { should classify('Mozilla/5.0 (Linux; U; Android 2.2; es-es; GT-P1000 Build/FROYO) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1').as('android') }
      it { should classify('Opera/9.80 (J2ME/MIDP; Opera Mini/9.80 (S60; SymbOS; Opera Mobi/23.348; U; en) Presto/2.5.25 Version/10.54').as('operamini') }
      it { should classify('Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320)').as('windowsce') }
      it { should classify('Bjaaland').as('bot') }
      it { should classify('Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)').as('msie') }
      it { should classify('Mozilla/6.0 (Macintosh; I; Intel Mac OS X 11_7_9; de-LI; rv:1.9b4) Gecko/2012010317 Firefox/10.0a4').as('firefox') }
      it { should classify('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/535.20 (KHTML, like Gecko) Chrome/19.0.1036.7 Safari/535.20').as('chrome') }
      it { should classify('Mozilla/5.0 (compatible; Konqueror/4.5; FreeBSD) KHTML/4.5.4 (like Gecko)').as('konqueror') }
      it { should classify('Opera/9.80 (Windows NT 6.1; U; es-ES) Presto/2.9.181 Version/12.00').as('opera') }
      it { should classify('Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; de-at) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1').as('safari') }
      it { should classify('Mozilla/4.0 (compatible; MSIE 8.0; AOL 9.7; AOLBuild 4343.27; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)').as('aol') }
      it { should classify('CatchAll').as('catchall') }
    end
  end
end