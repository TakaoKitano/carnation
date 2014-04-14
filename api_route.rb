require 'date'
require 'json'
require 'carnation'

class ApiRoute < Sinatra::Base

  configure :development do 
    Bundler.require :development 
    register Sinatra::Reloader 
    also_reload './carnation.rb'
    also_reload './models.rb'
    p "Sinatra::Reloader registered"
  end 

  def initialize
    super
    @carnation = Carnation.new
  end

  use Rack::OAuth2::Server::Resource::Bearer do |request|
    access_token = request.access_token || request.invalid_token!
    p "access_token=" + access_token
    token = AccessToken.where(:token => request.access_token).first || request.invalid_token!
    p "expires_at=" + token.expires_at.to_i.to_s
    p "       now=" + DateTime.now.to_i.to_s
    if token.expires_at.to_i < DateTime.now.to_i
      p "token expired"
      request.invalid_token!
    end
    token
  end

  get '/carnation/api/initiate_upload' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
    response['Content-Type'] = 'application/json'
    ret = @carnation.initiate_upload(request.params)
    JSON.pretty_generate(ret)
  end

  get '/carnation/api/notify_uploaded' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
    response['Content-Type'] = 'application/json'
    ret = @carnation.notify_uploaded(request.params)
    JSON.pretty_generate(ret)
  end

  get '/carnation/api/get_user_images' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
    response['Content-Type'] = 'application/json'
    ret = @carnation.get_user_images(request.params)
    JSON.pretty_generate(ret)
  end

  get '/api/*' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
    "get api request"
  end
end
