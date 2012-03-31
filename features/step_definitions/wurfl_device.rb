require 'zlib' 
require 'open-uri'

Given /^WurflDevice is used like:$/ do |string|
  instance_eval(string)
end

When /^I download "([^"]*)" saving it as "([^"]*)"$/ do |url, filename|
  File.open(File.expand_path(filename, current_dir), 'w') { |f| f.write(Zlib::GzipReader.new(open(url)).read) }
end

When /^I initialize the cache using xml file at "([^"]*)"$/ do |arg1|
  WurflDevice::Cache.initialize_cache!(File.expand_path(arg1, current_dir))
end

Then /^I should see the cache initialized$/ do
  WurflDevice::Cache.valid?.should be(true)
end

Then /^I should at least see a "([^"]*)" handset$/ do |arg1|
  WurflDevice::Handset[arg1].id.should == arg1
end
