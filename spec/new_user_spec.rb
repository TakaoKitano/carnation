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
    user = User.find(:email=>@test_email)
    user.destroy if user

    @user = User.find(:email=>"test01@chikaku.com")
    @access_token = AccessToken.new(@user).save
    @token = @access_token.token

    @signup_user = User.find(:email=>"signup@chikaku.com")
    expect(@signup_user).not_to be(nil)
    @signup_access_token = AccessToken.new(@signup_user).save
    expect(@signup_access_token).not_to be(nil)
    @signup_token = @signup_access_token.token

    @admin_user = User.find(:email=>"admin@chikaku.com")
    expect(@admin_user).not_to be(nil)
    @admin_access_token = AccessToken.new(@admin_user).save
    expect(@admin_access_token).not_to be(nil)
    @admin_token = @admin_access_token.token

    @test_email = "testtest@chikaku.com"
  end

  describe "create new user" do
    it "should fail with normal user token" do
      post '/api/v1/user/create', {:email=>@test_email, :password=>"abc", :access_token=>@token}
      expect(last_response).not_to be_ok
    end

    it "should fail without email" do
      post '/api/v1/user/create', {:password=>"abc", :access_token=>@signup_token}
      expect(last_response).not_to be_ok
    end

    it "should fail without password" do
      post '/api/v1/user/create', {:email=>@test_email, :access_token=>@signup_token}
      expect(last_response).not_to be_ok
    end

    it "should fail if same email exists " do
      post '/api/v1/user/create', {:email=>"test01@chikaku.com", :password=>"abc", :access_token=>@signup_token}
      expect(last_response).not_to be_ok
    end

    it "should be OK with signup user account" do
      post '/api/v1/user/create', {:email=>@test_email, :password=>"abc", :access_token=>@signup_token}
      expect(last_response).to be_ok
    end
  end

  describe "create and get info and delete user" do
    it "should be OK with signup user account" do
      post '/api/v1/user/create', {:email=>@test_email, :password=>"abc", :access_token=>@signup_token}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)

      new_user_id = result["id"]
      new_user_email = result["email"]
      new_user_name = result["name"]
      expect(result["email"]).to eq(@test_email)

      get '/api/v1/user', {:user_id=>new_user_id, :access_token=>@admin_token}
      expect(last_response).to be_ok

      get '/api/v1/user/delete', {:user_id=>new_user_id, :access_token=>@admin_token}
      expect(last_response).to be_ok
    end
  end

  describe "create and set attribute of user" do
    it "should be OK with signup user account" do
      post '/api/v1/user/create', {:email=>@test_email, :password=>"abc", :access_token=>@signup_token}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)

      new_user_id = result["id"]
      new_user_email = result["email"]
      new_user_name = result["name"]
      expect(result["email"]).to eq(@test_email)

      user = User.find(:email=>new_user_email)
      access_token = AccessToken.new(user).save
      token = access_token.token

      post '/api/v1/user/attributes', {:user_id=>new_user_id, :access_token=>token}
      expect(last_response).to be_ok

      post '/api/v1/user/attributes', {:user_id=>new_user_id, :access_token=>token, :password=>"yesyes"}
      expect(last_response).to be_ok
      post '/api/v1/user/attributes', {:user_id=>new_user_id, :access_token=>token, :email=>"yesyes@email.com"}
      post '/api/v1/user/attributes', {:user_id=>new_user_id, :access_token=>token, :name=>"yesman"}
      expect(last_response).to be_ok

      post '/api/v1/user/attributes', {:user_id=>new_user_id, :access_token=>token, :email=>"test01@chikaku.com"}
      expect(last_response).not_to be_ok

      get '/api/v1/user/delete', {:user_id=>new_user_id, :access_token=>@admin_token}
      expect(last_response).to be_ok

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


  after do
    @access_token.destroy if @access_token
    @signup_access_token.destroy if @signup_access_token
    @admin_access_token.destroy if @admin_access_token
    user = User.find(:email=>@test_email)
    user.destroy if user
  end

end
