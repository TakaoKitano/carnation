require File.dirname(__FILE__) + '/spec_helper'

require 'pp'
require 'json'
require 'token.rb'

describe "/token" do
  include Rack::Test::Methods

  def app
    Token
  end

  context "viewer token" do
    it "should be OK with proper credentials" do
      authorize "6052d5885f9c2a12c09ef90f815225d3","f6af879a7db8bfbe183e08c1a68e9035"
      post '/token','grant_type=client_credentials'
      expect(last_response).to be_ok
    end

    it "should not be OK without credentials" do
      post '/token','grant_type=client_credentials'
      expect(last_response).not_to be_ok
    end

    it "should not be OK with bad credentials" do
      authorize "badappid","badsecret"
      post '/token','grant_type=client_credentials'
      expect(last_response).not_to be_ok
    end

    it "should not be OK with bad grant_type" do
      authorize "6052d5885f9c2a12c09ef90f815225d3","f6af879a7db8bfbe183e08c1a68e9035"
      post '/token','grant_type=unknown_bad_grant_type'
      expect(last_response).not_to be_ok
    end
  end

  context "appuser token" do
    before do
      @appid = 'e3a5cde0f20a94559691364eb5fb8bff'
      @secret = '116dd4b3a92a17453df0a5ae83e5e640'
    end

    it "should be OK with proper credentials" do
      authorize @appid, @secret
      post '/token', "grant_type=password&username=test01@chikaku.com&password=dx7PnxqDZ5kr"
      expect(last_response).to be_ok
    end

    it "should be OK with admin credential" do
      authorize @appid, @secret
      post '/token', "grant_type=password&username=admin@chikaku.com&password=Zh1lINR0H1sw"
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result["access_token"]).not_to eq(nil)
      expect(result["token_type"]).to eq("bearer")
      expect(result["user_id"]).to eq(1)
      expect(result["expires_in"]).to be > 0
    end

    it "should be OK with signup user  credential" do
      authorize @appid, @secret
      post '/token', "grant_type=password&username=signup@chikaku.com&password=9TseZTFYR1ol"
      result = JSON.parse(last_response.body)
      expect(last_response).to be_ok
      expect(result["access_token"]).not_to eq(nil)
      expect(result["token_type"]).to eq("bearer")
      expect(result["user_id"]).to eq(2)
      expect(result["expires_in"]).to be > 0
    end

    it "should be OK with default  user credential" do
      authorize @appid, @secret
      post '/token', "grant_type=password&username=default@chikaku.com&password=6y6bSoTwmKIO"
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result["access_token"]).not_to eq(nil)
      expect(result["token_type"]).to eq("bearer")
      expect(result["user_id"]).to eq(3)
      expect(result["expires_in"]).to be > 0
    end

    it "should not be OK without credentials" do
      post '/token', "grant_type=password&username=test01@chikaku.com&password=dx7PnxqDZ5kr"
      expect(last_response).not_to be_ok
    end

    it "should not be OK with bad credentials" do
      authorize "badappid","badsecret"
      post '/token', "grant_type=password&username=test01@chikaku.com&password=dx7PnxqDZ5kr"
      expect(last_response).not_to be_ok
    end

    it "should not be OK with bad password" do
      authorize @appid, @secret
      post '/token', "grant_type=password&username=test01@chikaku.com&password=bad"
      expect(last_response).not_to be_ok
    end

    it "should not be OK with bad user and password" do
      authorize @appid, @secret
      post '/token', "grant_type=password&username=bad&password=bad"
      expect(last_response).not_to be_ok
    end
  end

end
