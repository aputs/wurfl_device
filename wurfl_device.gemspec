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

  s.add_dependency 'hiredis'
  s.add_dependency 'redis'
  s.add_dependency 'thor'
  s.add_dependency 'ox'
  s.add_dependency 'text'
  s.add_dependency 'sinatra'
  s.add_dependency 'unicorn'

  s.add_development_dependency 'bundler', '>= 1.0.10'
  s.add_development_dependency 'rake', '>= 0.9.2'
  s.add_development_dependency 'rspec-core', '~> 2.0'
  s.add_development_dependency 'rspec-expectations', '~> 2.0'
  s.add_development_dependency 'rr', '~> 1.0'
  s.add_development_dependency 'simplecov', '~> 0.5.3'
  s.add_development_dependency 'fakeredis', '~> 0.2.2'

  s.requirements    << 'redis server'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths    = ["lib"]
  s.extra_rdoc_files = ["LICENSE", "README.md"]
end
