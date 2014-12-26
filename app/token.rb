require 'sinatra/base'
require 'rack/oauth2'
require 'models'

class Token < Sinatra::Base

  configure :development do
    Bundler.require :development
    register Sinatra::Reloader
    also_reload 'app/models.rb'
    CarnationConfig.logger.info "Sinatra::Reloader registered for token"
  end

  helpers do
    def cors_headers
      headers['Access-Control-Allow-Methods'] = '*'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Authorization,X-Requested-With'
    end

    def log(s)
      #CarnationConfig.logger.info(s)
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
    log"TokenEndpoint authenticator call"
    Rack::OAuth2::Server::Token.new do |req, res|
      log "Rack::OAuth2::Server::Token callback"
      log "req.grant_type=" + req.grant_type.to_s

      #
      # check client credential
      #
      log "client_id=" + req.client_id + " client_secret=" + req.client_secret
      client = Client.where(:appid => req.client_id).first 
      if not client
        log "appid is invalid"
        log "req.client_id=" + req.client_id
        req.invalid_client!
      end
      if (client.secret != req.client_secret) 
        log "secret is invalid"
        req.invalid_client!
      end

      case req.grant_type
      #
      # right now, we only support password,client_credentials and refresh_token
      #
      when :password 
        #
        # check username and password
        #
        log "password grant_type token request, id and secret is OK"
        log "req.username=" + req.username + " req.password=" + req.password
        user = User.find(:email=>req.username) || req.invalid_grant!
 
        if user.password_hash == Digest::SHA256.hexdigest(user.password_salt + req.password)
          access_token = AccessToken.create_new_token(user).save
          res.access_token = access_token.generate_bearer_token
        else
          log "user password unmatch"
          req.invalid_grant!
        end

      when :client_credentials 
        log "client_credentials token request, id and secret is OK"
        log "client.appid=" + client.appid
        log "client.secret=" + client.secret
        viewer = client.viewer
        if viewer
          access_token = AccessToken.create_new_token(viewer).save
          res.access_token = access_token.generate_bearer_token
        else
          log "viewer not found"
          req.invalid_grant!
        end

      when :refresh_token 
        log "refresh_token request"
        if req.refresh_token
          log "refresh_token=#{req.refresh_token}"
          access_token = AccessToken.find(:refresh_token=>req.refresh_token) || req.invalid_grant!
          if access_token
            access_token = access_token.refresh
            res.access_token = access_token.generate_bearer_token
          else
            req.invalid_grant!
          end
        else
          log "refresh_token is not provided"
          req.invalid_grant!
        end

      else
        req.unsupported_grant_type!
      end
    end
  end
end
