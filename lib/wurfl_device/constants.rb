# -*- encoding: utf-8 -*-
module WurflDevice
  class Constants
    LOCK_TIMEOUT                  = 3
    LOCK_EXPIRE                   = 10
    LOCK_SLEEP                    = 0.1

    DB_INDEX                      = "7".freeze
    GENERIC                       = 'generic'
    WURFL                         = "wurfl:"
    WURFL_INFO                    = "wurfl:info"
    WURFL_DEVICES                 = "wurfl:devices:"
    WURFL_DEVICES_INDEX           = "wurfl:index:"
    WURFL_INITIALIZED             = "wurfl:is_initialized"
    WURFL_INITIALIZING            = "wurfl:is_initializing"
    WURFL_USER_AGENTS             = "wurfl:user_agents"
    WURFL_USER_AGENTS_CACHED      = "wurfl:user_agents_cached"

    USER_AGENT_MATCHERS =
    [
      "Alcatel", "Android", "AOL", "Apple", "BenQ", "BlackBerry", "Bot", "CatchAll", "Chrome", "DoCoMo",
      "Firefox", "Grundig", "HTC", "Kddi", "Konqueror", "Kyocera", "LG", "Mitsubishi", "Motorola", "MSIE",
      "Nec", "Nintendo", "Nokia", "Opera", "OperaMini", "Panasonic", "Pantech", "Philips", "Portalmmm", "Qtek",
      "Safari", "Sagem", "Samsung", "Sanyo", "Sharp", "Siemens", "SonyEricsson", "SPV", "Toshiba", "Vodafone", "WindowsCE"
    ]

    MOBILE_BROWSERS   =  [
      'cldc', 'symbian', 'midp', 'j2me', 'mobile', 'wireless', 'palm', 'phone', 'pocket pc', 'pocketpc', 'netfront',
      'bolt', 'iris', 'brew', 'openwave', 'windows ce', 'wap2.', 'android', 'opera mini', 'opera mobi', 'maemo', 'fennec',
      'blazer', 'vodafone', 'wp7', 'armv'
    ]

    ROBOTS            = [ 'bot', 'crawler', 'spider', 'novarra', 'transcoder', 'yahoo! searchmonkey', 'yahoo! slurp', 'feedfetcher-google', 'toolbar', 'mowser' ]
    DESKTOP_BROWSERS  = [ 'slcc1', '.net clr', 'wow64', 'media center pc', 'funwebproducts', 'macintosh', 'aol 9.', 'america online browser', 'googletoolbar' ]
  end
end
