require 'etc'
require 'nokogiri'

module WurflDevice
  class XmlLoader
    def self.load_xml_file(wurfl_file, &blk)
      devices = Hash.new

      xml = Nokogiri::XML File.open(wurfl_file)

      version = xml.xpath('//version/ver')[0].children.to_s rescue nil
      last_updated = DateTime.parse(xml.xpath('//version/last_updated')[0].children.to_s) rescue nil

      xml.xpath('//devices/*').each do |element|
        wurfl_id = 'generic'
        user_agent = 'generic'
        fall_back = nil
        if element.attributes["id"].to_s != "generic"
          wurfl_id = element.attributes["id"].to_s
          user_agent = element.attributes["user_agent"].to_s
          user_agent = 'generic' if user_agent.empty?
          fall_back = element.attributes["fall_back"].to_s
        end

        device = Hash.new
        device['id'] = wurfl_id
        device['user_agent'] = user_agent
        device['fall_back'] = fall_back

        element.xpath('.//*').each do |group|
          group_id = group.attributes["id"].to_s
          next if group_id.empty?
          group_capa = Hash.new
          group.xpath('.//*').each do |capability|
            name = capability.attributes["name"].to_s
            next if name.empty?
            group_capa[name] = WurflDevice.parse_string_value(capability.attributes["value"].to_s)
          end
          device[group_id] = group_capa
        end

        devices[wurfl_id] = device
        yield device if block_given?
      end

      [devices, version, last_updated]
    end
  end
end
