Given /^WurflDevice cached is initialized$/ do
  steps %Q{
    When I successfully run `bundle install`
    And I successfully run `rake wurfl:init`
  }
end

When /^I download "([^"]*)" saving it as "([^"]*)"$/ do |arg1, arg2|
  File.open(File.expand_path(arg2, current_dir), 'w') { |f| f.write(Zlib::GzipReader.new(open(arg1)).read) }
end

When /^I initialize the cache using xml file "([^"]*)"$/ do |arg1|
  WurflDevice::Cache.initialize_cache!(File.expand_path(arg1, current_dir))
end

Then /^I should see the cache initialized$/ do
  WurflDevice::Cache.valid?.should be(true)
end

Then /^I should see a "([^"]*)" handset$/ do |arg1|
  WurflDevice::Cache.handsets[arg1].id.should == arg1
end
