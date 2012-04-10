# encoding: utf-8
module WurflDevice
  class Config
    attr_accessor :xml_url
    attr_writer :xml_file
    attr_writer :redis_host, :redis_port, :redis_path, :redis_db
    attr_writer :worst_match

    def xml_file
      @xml_file ||= '/tmp/wurfl.xml'
    end

    def redis_host
      @redis_host ||= '127.0.0.1'
    end

    def redis_port
      @redis_port ||= 6379
    end

    def redis_path
      @redis_path ||= nil
    end

    def redis_db
      @redis_db ||= 0
    end

    def worst_match
      @worst_match ||= 7
    end
  end
end