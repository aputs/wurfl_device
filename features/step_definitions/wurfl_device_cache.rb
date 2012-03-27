require 'zlib' 
require 'open-uri'

Given /^WurflDevice is used like:$/ do |string|
  instance_eval(string)
end

Given /^gzipped files is at:$/ do |table|
  @gzipped_files_to_download = table.hashes
end

When /^I download the files saving them at "([^"]*)"$/ do |arg1|
  @gzipped_files_root_dir = arg1
  FileUtils.mkdir_p(@gzipped_files_root_dir)
  @gzipped_files_to_download.each do |gzipped|
    gzipped_file = File.join(@gzipped_files_root_dir, gzipped['filename'])
    next if File.exists?(gzipped_file)
    File.open(gzipped_file, 'w') do |f|
      f.write(Zlib::GzipReader.new(open(gzipped['url'])).read)
    end
  end
end

Then /^I should see the xml files$/ do
  @gzipped_files_to_download.each do |file|
    File.should be_exist(File.join(@gzipped_files_root_dir, file['filename']))
  end
end

Given /^wurfl xml file at:$/ do |table|
  @wurfl_xml_files = table.hashes.map { |i| i['filename'] }
end

When /^I inititialize cache$/ do
  WurflDevice::Cache.initialize_cache! @wurfl_xml_files
end

Then /^I should see the cache initialized$/ do
  WurflDevice::Cache.initialized?.should be(true)
end