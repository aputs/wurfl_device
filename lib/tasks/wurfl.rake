require 'wurfl_device'

namespace :wurfl do
  desc "download wurfl xml from sourceforge and store in tmp folder"
  task :download do
    puts "downloading to #{WurflDevice::Settings::TMP_DIR}"
    `(curl -Ls http://sourceforge.net/projects/wurfl/files/WURFL/2.3/wurfl-2.3.xml.gz/download) | zcat > #{WurflDevice::Settings::TMP_DIR}/wurfl.xml`
    `(curl -Ls http://sourceforge.net/projects/wurfl/files/WURFL/2.3/web_browsers_patch.xml/download) > #{WurflDevice::Settings::TMP_DIR}/web_browsers_patch.xml`
  end

  desc "initialize wurfl device cache"
  task :initialize_cache do
    puts "initializing wurfl device cache"
    WurflDevice::Cache.clear
    WurflDevice::Cache.initialize_cache(WurflDevice::Settings.default_wurfl_xml_file)
  end
end