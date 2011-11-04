# encoding: utf-8
require 'yaml'
require 'wurfl_device'
require 'sinatra/base'

module WurflDevice
  class WebService < Sinatra::Base
    get '/' do
      user_agent = request.env['HTTP_USER_AGENT']
      user_agent = WurflDevice::Settings::GENERIC if user_agent.nil? || user_agent.empty?
      capabilities = WurflDevice.capabilities_from_user_agent(user_agent)
      capabilities.to_yaml
    end

    get '/capability/:id' do
      user_agent = request.env['HTTP_USER_AGENT']
      user_agent = WurflDevice::Settings::GENERIC if user_agent.nil? || user_agent.empty?
      capability = WurflDevice.capability_from_user_agent(params[:id], user_agent)
      capability.to_yaml
    end

    get '/device/:id' do
      capabilities = WurflDevice.capabilities_from_id(params[:id])
      capabilities.to_yaml
    end
  end
end
