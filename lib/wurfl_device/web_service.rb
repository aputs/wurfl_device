# encoding: utf-8
require 'yaml'
require 'wurfl_device'
require 'sinatra/base'

module WurflDevice
  class WebService < Sinatra::Base
    get '/' do
      user_agent = request.env['HTTP_USER_AGENT'] || '-'
      device = WurflDevice.get_device_from_ua(user_agent)
      return device.capabilities.to_yaml unless device.nil?
      {}.to_yaml
    end

    get '/:capa' do
      user_agent = request.env['HTTP_USER_AGENT'] || '-'
      device = WurflDevice.get_device_from_ua(user_agent)
      return device.send(params[:capa]).to_yaml unless device.nil?
      {}.to_yaml
    end

    get '/device/:id' do
      device = WurflDevice.get_device_from_id(params[:id])
      capabilities = {}
      capabilities = device.capabilities unless device.nil?
      capabilities.to_yaml
    end

    get '/device/:id/:capa' do
      device = WurflDevice.get_device_from_id(params[:id])
      capability = {}
      capability = device.send(params[:capa]) unless device.nil?
      capability.to_yaml
    end

    get '/actual_device/:id' do
      capabilities = WurflDevice.get_actual_device(params[:id])
      capabilities.to_yaml
    end

    get '/actual_device/:id/:capa' do
      capabilities = WurflDevice.get_actual_device(params[:id])
      get_capa(params[:capa], capabilities).to_yaml
    end

  protected
    def get_capa(capa, capabilities)
      capability = nil
      if capabilities.has_key?(capa)
        capability = capabilities.send(capa)
      else
        capabilities.each_pair do |key, value|
          if value.is_a?(Hash)
            capability = value.send(capa)
            break
          end
        end
      end
      return capability
    end
  end
end
