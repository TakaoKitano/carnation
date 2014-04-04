class Token < Sinatra::Base

  post '/token' do
    authenticator.call(env)
  end

  private 

  def generate_bearer_token (access_token)
    sec = access_token.expires_at.to_time.to_i - access_token.created_at.to_time.to_i
    bearer_token = Rack::OAuth2::AccessToken::Bearer.new(
      :access_token => access_token.token,
      :user_id => access_token.user_id,
      :expires_in => sec
    )
  end

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
        user = User.where(:name => req.username).first || req.invalid_grant!
 
        if user.password_hash == Digest::SHA256.hexdigest(user.password_salt + req.password)
          access_token = AccessToken.create(user.id).save
          res.access_token = generate_bearer_token(access_token)
        else
          p "user password unmatch"
          req.invalid_grant!
        end
      when :client_credentials 
        p "client_credentials token request, id and secret is OK"
        #stb = Stb.where(:client_id => client.id).first
        stb = client.stb
        #p stb
        if stb && stb.user_id
          access_token = AccessToken.create(stb.user_id).save
          res.access_token = generate_bearer_token(access_token)
        else
          p "stb not found, or stb is not binding to an user"
          req.invalid_grant!
        end
      else
          req.unsupported_grant_type!
      end
    end
  end
end
