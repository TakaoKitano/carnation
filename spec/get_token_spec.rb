require File.dirname(__FILE__) + '/spec_helper'

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
    it "should be OK with proper credentials" do
      authorize 'e3a5cde0f20a94559691364eb5fb8bff', '116dd4b3a92a17453df0a5ae83e5e640'
      post '/token', "grant_type=password&username=test01@chikaku.com&password=dx7PnxqDZ5kr"
      expect(last_response).to be_ok
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
      authorize 'e3a5cde0f20a94559691364eb5fb8bff', '116dd4b3a92a17453df0a5ae83e5e640'
      post '/token', "grant_type=password&username=test01@chikaku.com&password=bad"
      expect(last_response).not_to be_ok
    end

    it "should not be OK with bad user and password" do
      authorize 'e3a5cde0f20a94559691364eb5fb8bff', '116dd4b3a92a17453df0a5ae83e5e640'
      post '/token', "grant_type=password&username=bad&password=bad"
      expect(last_response).not_to be_ok
    end
  end

end
