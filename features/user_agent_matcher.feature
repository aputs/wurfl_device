@ok
Feature:

  I must be able to match user agent

  Scenario Outline:
    When I successfully initialize the cache
    Then matching "<user_agent>" should be "<handset_id>"

    Examples:
    | handset_id                      | user_agent                                                                                                                        |
    | rim_playbook_ver1               | Mozilla/5.0 (PlayBook; U; RIM Tablet OS 1.0.0; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/0.0.1 Safari/534.8+          |
    | blackberry9100_ver1_subos6      | Mozilla/5.0 (BlackBerry; U; BlackBerry AAAA; en-US) AppleWebKit/534.11+ (KHTML, like Gecko) Version/X.X.X.X Mobile Safari/534.11+ |
    | sonyericsson_k700i_ver1_subr2ay | SonyEricssonK700i/R2AG SEMC-Browser/4.0.3 Profile/MIDP-2.0 Configuration/CLDC-1.1                                                 |
    | samsung_sgh_e200_ver1           | SAMSUNG-SGH-E200/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 UP.Browser/6.2.3.3.c.1.101 (GUI) MMP/2.0                             |
