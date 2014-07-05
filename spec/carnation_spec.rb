require File.dirname(__FILE__) + '/spec_helper'

require 'pp'
require 'json'
require 'carnation.rb'

describe Carnation do
  include Rack::Test::Methods

  def app
    Carnation
  end

  before do
    @user = User.find(:email=>"test01@chikaku.com")
    @access_token = AccessToken.new(@user).save
    @token = @access_token.token

    @signup_user = User.find(:email=>"signup@chikaku.com")
    expect(@signup_user).not_to be(nil)
    @signup_access_token = AccessToken.new(@signup_user).save
    expect(@signup_access_token).not_to be(nil)
    @signup_token = @access_token.token
  end

  describe "create new user" do
    it "should fail with normal user token" do
      post '/api/v1/user/create', {:email=>"test09@chikaku.com", :access_token=>@token}
      expect(last_response).not_to be_ok
    end
  end

  describe "get user info" do
    it "should be OK with token" do
      get '/api/v1/user', {:user_id=>@user.id, :access_token=>@token}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result["id"]).to eq(@user.id)
      expect(result["email"]).to eq(@user.email)
      expect(result["name"]).to eq(@user.name)
    end

    it "should return 400 without token" do
      get '/api/v1/user', {:user_id=>@user.id}
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq(400)
    end

    it "should return 404 with bad user_id" do
      get '/api/v1/user', {:user_id=>-1, :access_token=>@token}
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq(404)
    end

  end

  describe "get user id by email" do

    it "should be OK with email and token" do
      get '/api/v1/user_by_email', {:email=>@user.email, :access_token=>@token}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result["user_id"]).to eq(@user.id)
    end

    it "should return 404 with bad email" do
      get '/api/v1/user_by_email', {:email=>"bad@bad.com", :access_token=>@token}
      expect(last_response.status).to eq(404)
    end

    it "should return 400 without token" do
      get '/api/v1/user_by_email', {:email=>@user.email}
      expect(last_response.status).to eq(400)
    end

  end

  describe "post initiate item upload" do
    it "should be OK with user_id, extension and token" do
      post '/api/v1/item/initiate', {:user_id=>@user.id, :extension=>".jpg", :access_token=>@token}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result['item_id']).to be > 0
      expect(result['status']).to eq(0)
      expect(result['url'].length).to be >0
      expect(result['url'].index('https')).to eq(0)
      delete '/api/v1/item', {:item_id=>result['item_id'], :access_token=>@token}
      expect(last_response).to be_ok
    end

    it "should not be OK without token" do
      post '/api/v1/item/initiate', {:user_id=>@user.id, :extension=>".jpg"}
      expect(last_response.status).to eq(400)
    end

    it "should not be OK without user_id" do
      post '/api/v1/item/initiate', {:extension=>".jpg", :access_token=>@token}
      expect(last_response.status).to eq(400)
    end

    it "should not be OK without extension" do
      post '/api/v1/item/initiate', {:user_id=>@user.id, :access_token=>@token}
      expect(last_response.status).to eq(400)
    end

    it "should not be OK with invalid user_id" do
      post '/api/v1/item/initiate', {:user_id=>-1, :extension=>".jpg", :access_token=>@token}
      expect(last_response.status).to eq(400)
    end

  end

  after do
    @access_token.destroy if @access_token
    @signup_access_token.destroy if @signup_access_token
  end

end
