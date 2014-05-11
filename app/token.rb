require 'sinatra/base'
require 'rack/oauth2'
require 'models'

class Token < Sinatra::Base

  helpers do
    def cors_headers
      headers['Access-Control-Allow-Methods'] = '*'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Authorization'
    end
  end

  before do
    cors_headers
  end

  options '*' do
    cors_headers
    halt 200
  end

  post '/token' do
    authenticator.call(env)
  end

  private 

  def authenticator
    #p "TokenEndpoint authenticator call"
    Rack::OAuth2::Server::Token.new do |req, res|
      #p "Rack::OAuth2::Server::Token callback"
      #p "req.grant_type=" + req.grant_type.to_s

      #
      # check client credential
      #
      #p "client_id=" + req.client_id + " client_secret=" + req.client_secret
      client = Client.where(:appid => req.client_id).first 
      if not client
        #p "appid is invalid"
        #p "req.client_id=" + req.client_id
        req.invalid_client!
      end
      if (client.secret != req.client_secret) 
        #p "secret is invalid"
        req.invalid_client!
      end

      case req.grant_type
      #
      # right now, we only support password and client_credentials
      #
      when :password 
        #
        # check username and password
        #
        #p "password grant_type token request, id and secret is OK"
        #p "req.username=" + req.username + " req.password=" + req.password
        user = User.find(:email=>req.username) || req.invalid_grant!
 
        if user.password_hash == Digest::SHA256.hexdigest(user.password_salt + req.password)
          access_token = AccessToken.new(user).save
          res.access_token = access_token.generate_bearer_token
        else
          #p "user password unmatch"
          req.invalid_grant!
        end
      when :client_credentials 
        #p "client_credentials token request, id and secret is OK"
        #p "client.appid=" + client.appid
        #p "client.secret=" + client.secret
        viewer = client.viewer
        if viewer
          access_token = AccessToken.new(viewer).save
          res.access_token = access_token.generate_bearer_token
        else
          #p "viewer not found"
          req.invalid_grant!
        end
      else
        req.unsupported_grant_type!
      end
    end
  end
end
