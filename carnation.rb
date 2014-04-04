require 'date'

class Carnation < Sinatra::Base

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

  get '/api/*' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
    "get api request"
  end
end
