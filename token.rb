class Token < Sinatra::Base

  post '/token' do
    authenticator.call(env)
  end

  private 

  def authenticator
    p "TokenEndpoint authenticator call"
    Rack::OAuth2::Server::Token.new do |req, res|
      #
      # check client credential
      #
      #p "client_id=" + req.client_id + " client_secret=" + req.client_secret
      client = Client.where(:appid => req.client_id).first || req.invalid_client!
      if (client.secret != req.client_secret) 
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
        p "password grant_type token request, id and secret is OK"
        #p "req.username=" + req.username + " req.password=" + req.password
        user = User.where(:email => req.username).first || req.invalid_grant!
 
        if user.password_hash == Digest::SHA256.hexdigest(user.password_salt + req.password)
          access_token = AccessToken.new(user).save
          res.access_token = access_token.generate_bearer_token
        else
          p "user password unmatch"
          req.invalid_grant!
        end
      when :client_credentials 
        p "client_credentials token request, id and secret is OK"
        viewer = client.viewer
        if viewer
          access_token = AccessToken.new(viewer).save
          res.access_token = access_token.generate_bearer_token
        else
          p "viewer not found"
          req.invalid_grant!
        end
      else
          req.unsupported_grant_type!
      end
    end
  end
end
