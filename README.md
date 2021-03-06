WurflDevice
===========
Ruby client library for mobile handset detection


Requirements
------------
* [redis server](http://redis.io/)


Installation
------------
install using rubygems

    gem install wurfl_device

or add to your Gemfile:

    gem 'wurfl_device'

and install it via Bundler:

    $ bundle


Usage
-----

    require 'wurfl_device'

initialize the device cache

    WurflDevice.initialize_cache!

get handset capabilities hash from user agent

    user_agent = 'Mozilla/5.0 (SymbianOS/9.2; U; Series60/3.1 NokiaN95_8GB/20.0.016; Profile/MIDP-2.0 Configuration/CLDC-1.1 ) AppleWebKit/413 (KHTML, like Gecko) Safari/413'
    capabilities = WurflDevice.handset_from_user_agent(user_agent)

get handset capabilities hash from device id

    device_id = 'generic'
    capabilities = WurflDevice.handset_from_device_id(device_id)

