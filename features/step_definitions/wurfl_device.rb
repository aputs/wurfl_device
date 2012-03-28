require 'zlib' 
require 'open-uri'

Given /^WurflDevice is used like:$/ do |string|
  instance_eval(string)
end

Given /^gzipped xml file at "([^"]*)"$/ do |url|
  @gzipped_url_to_download = url
end

When /^I download the xml file saving it as "([^"]*)"$/ do |xml_file|
  @saved_xml_file = xml_file
  next if File.exists?(xml_file)
  File.open(xml_file, 'w') { |f| f.write(Zlib::GzipReader.new(open(@gzipped_url_to_download)).read) }
end

Then /^I should see the xml file$/ do
  File.should be_exist(@saved_xml_file)
end

When /^I initialize the cache using xml file at "([^"]*)"$/ do |arg1|
  WurflDevice::Cache.initialize_cache!(arg1)
end

Then /^I should see the cache initialized$/ do
  WurflDevice::Cache.valid?.should be(true)
end

Then /^I should at least see a "([^"]*)" device$/ do |arg1|
  WurflDevice::Cache.devices[arg1].should_not be(nil)
end

