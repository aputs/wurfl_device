# WurflDevice
Ruby client library for mobile handset detection


requirements
------------
  * [redis server](http://redis.io/)


usage
-----

    require 'wurfl_device'

    user_agent = 'Mozilla/5.0 (SymbianOS/9.2; U; Series60/3.1 NokiaN95_8GB/20.0.016; Profile/MIDP-2.0 Configuration/CLDC-1.1 ) AppleWebKit/413 (KHTML, like Gecko) Safari/413'

    device = WurflDevice.get_device_from_ua(user_agent)

    # see device capabilities list for names
    puts device.id


