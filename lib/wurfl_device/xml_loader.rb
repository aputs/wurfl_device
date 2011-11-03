# encoding: utf-8
require 'ox'

module WurflDevice
  class XmlLoader
    def self.load_xml_file(wurfl_file, &blk)
      file_contents = File.open(wurfl_file).read.force_encoding('UTF-8')

      # TODO apparently Ox doesn't support UCS/Unicode chars???
      file_contents.gsub!(/\&\#x.+\;/, '')

      # parse xml using Ox
      doc = Ox.parse(file_contents)
      doc.nodes.map do |elem1|
        next unless elem1.value =~ /wurfl/i
        elem1.nodes.map do |elem2|
          # version info
          version_info = Hash.new
          if elem2.value == 'version'
            elem2.nodes.map do |e|
              if e.value == 'ver'
                version_info[:version] = e.nodes[0].to_s
              end
            end
            yield version_info if block_given?
          end

          # devices list
          if elem2.value == 'devices'
            elem2.nodes.map do |device|
              next unless device.value =~ /device/i
              capabilities = Hash.new
              capabilities['id'] = device.attributes[:id] || ''
              capabilities['user_agent'] = device.attributes[:user_agent] || ''
              capabilities['fall_back'] = device.attributes[:fall_back] || ''

              device.nodes.map do |group|
                next unless group.value =~ /group/i
                group.nodes.map do |capability|
                  capabilities[group.attributes[:id]] ||= Hash.new
                  next unless capability.value =~ /capability/i
                  capabilities[group.attributes[:id]][capability.attributes[:name]] = capability.attributes[:value]
                end
              end
              yield capabilities if block_given?
            end
          end
        end
      end
    end
  end
end
