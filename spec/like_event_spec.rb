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
    @viewer = @user.viewers[0]
    @viewer_access_token = AccessToken.new(@viewer).save
    @viewer_token = @viewer_access_token.token
  end

  describe "get /api/v1/user/items" do
    it "should be OK with token" do
      get '/api/v1/user/items', {:user_id=>@user.id, :access_token=>@token}
      expect(last_response).to be_ok
    end
    it "should not be OK without token" do
      get '/api/v1/user/items', {:user_id=>@user.id}
      expect(last_response).not_to be_ok
    end
    it "should not be OK without user_id" do
      get '/api/v1/user/items', {:access_token=>@token}
      expect(last_response).not_to be_ok
    end
  end

  describe "get /api/v1/user/items" do
    it "should be OK with viewer token" do
      get '/api/v1/user/items', {:user_id=>@user.id, :access_token=>@viewer_token}
      expect(last_response).to be_ok
    end
    it "should not be OK without token" do
      get '/api/v1/user/items', {:user_id=>@user.id}
      expect(last_response).not_to be_ok
    end
    it "should not be OK without user_id" do
      get '/api/v1/user/items', {:access_token=>@token}
      expect(last_response).not_to be_ok
    end
  end

  describe "post /api/v1/viewer/like increments counts" do
    it "should be OK with viewer token" do
      get '/api/v1/user/items', {:user_id=>@user.id, :item_id=>4, :access_token=>@viewer_token}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
     
      if result['items'][0]['liked_by'].length > 0
        count = result['items'][0]['liked_by'][0]['count']
      else
        count = 0
      end
      post '/api/v1/viewer/like', {:item_id=>4, :access_token=>@viewer_token}
      expect(last_response).to be_ok
      get '/api/v1/user/items', {:user_id=>@user.id, :item_id=>4, :access_token=>@viewer_token}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      count_after = result['items'][0]['liked_by'][0]['count']
      expect(count_after).to eq count+1
    end
  end

  describe "get /api/v1/user/events" do
    it "should be OK with user token" do
      get '/api/v1/user/events', {:user_id=>@user.id, :access_token=>@token}
      expect(last_response).to be_ok
    end
    it "should not be OK without token" do
      get '/api/v1/user/events', {:user_id=>@user.id}
      expect(last_response).not_to be_ok
    end
    it "should not be OK without user_id" do
      get '/api/v1/user/events', {:access_token=>@token}
      expect(last_response).not_to be_ok
    end
  end

  describe "post /api/v1/user/events/read" do
    it "should be OK with user token" do
      post '/api/v1/user/events/read', {:user_id=>@user.id, :access_token=>@token}
      expect(last_response).to be_ok
    end
    it "should be OK with user token and event_id" do
      post '/api/v1/user/events/read', {:user_id=>@user.id, :access_token=>@token, :event_id=>"4"}
      expect(last_response).to be_ok
    end
    it "should be OK with user token and multiple event_id" do
      post '/api/v1/user/events/read', {:user_id=>@user.id, :access_token=>@token, :event_id=>"4,5,6"}
      expect(last_response).to be_ok
    end
    it "should not be OK without token" do
      post '/api/v1/user/events/read', {:user_id=>@user.id}
      expect(last_response).not_to be_ok
    end
    it "should not be OK without user_id" do
      post '/api/v1/user/events/read', {:access_token=>@token}
      expect(last_response).not_to be_ok
    end
  end

  describe "post /api/v1/user/events/unread" do
    it "should be OK with user token" do
      post '/api/v1/user/events/unread', {:user_id=>@user.id, :access_token=>@token}
      expect(last_response).to be_ok
    end
    it "should be OK with user token and event_id" do
      post '/api/v1/user/events/unread', {:user_id=>@user.id, :access_token=>@token, :event_id=>"4"}
      expect(last_response).to be_ok
    end
    it "should be OK with user token and event_id" do
      post '/api/v1/user/events/unread', {:user_id=>@user.id, :access_token=>@token, :event_id=>"4,5,6"}
      expect(last_response).to be_ok
    end
    it "should not be OK without token" do
      post '/api/v1/user/events/unread', {:user_id=>@user.id}
      expect(last_response).not_to be_ok
    end
    it "should not be OK without user_id" do
      post '/api/v1/user/events/unread', {:access_token=>@token}
      expect(last_response).not_to be_ok
    end
  end

  describe "post /api/v1/user/events/retrieved" do
    it "should be OK with user token" do
      post '/api/v1/user/events/retrieved', {:user_id=>@user.id, :access_token=>@token}
      expect(last_response).to be_ok
    end
    it "should be OK with user token and event_id" do
      post '/api/v1/user/events/retrieved', {:user_id=>@user.id, :access_token=>@token, :event_id=>"4"}
      expect(last_response).to be_ok
    end
    it "should be OK with user token and event_id=0" do
      post '/api/v1/user/events/retrieved', {:user_id=>@user.id, :access_token=>@token, :event_id=>"0"}
      expect(last_response).to be_ok
    end
    it "should not be OK without token" do
      post '/api/v1/user/events/retrieved', {:user_id=>@user.id}
      expect(last_response).not_to be_ok
    end
    it "should not be OK without user_id" do
      post '/api/v1/user/events/unread', {:access_token=>@token}
      expect(last_response).not_to be_ok
    end
  end

  after do
    @access_token.destroy if @access_token
    @viewer_access_token.destroy if @viewer_access_token
  end

end
