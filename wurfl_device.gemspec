# -*- encoding: utf-8 -*-

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "wurfl_device/version"

Gem::Specification.new do |s|
  s.name        = "wurfl_device"
  s.version     = WurflDevice::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Allan Ralph Hutalla"]
  s.email       = ["ahutalla@gmail.com"]
  s.homepage    = "http://github.com/aputs/wurfl_device"
  s.summary     = %q{Ruby client library for mobile handset detection}
  s.description = %q{Ruby client library for mobile handset detection}

  s.rubyforge_project = 'wurfl_device'

  s.add_dependency 'libxml-ruby'
  s.add_dependency 'redis'
  s.add_dependency 'text'
  s.add_dependency 'thor'
  s.add_dependency 'puma'
  s.add_dependency 'daemons'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'hiredis'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'aruba'
  s.add_development_dependency 'cucumber'

  s.requirements    << 'redis server'

  s.files            = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.test_files       = Dir['spec/*', 'features/*']
  s.executables      = Dir["bin/*"].map{ |f| File.basename(f) }
  s.require_paths    = ["lib"]
  s.extra_rdoc_files = ["LICENSE", "README.md"]
end
