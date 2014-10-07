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
    Item.where(:file_hash=>"abc").destroy
  end

  describe "initiate item upload" do
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

    it "should be OK with timezone" do
      post '/api/v1/item/initiate', {:user_id=>@user.id, :extension=>".jpg", :access_token=>@token, :timezone=>-8}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result['item_id']).to be > 0
      expect(result['status']).to eq(0)
      expect(result['url'].length).to be >0
      expect(result['url'].index('https')).to eq(0)
      delete '/api/v1/item', {:item_id=>result['item_id'], :access_token=>@token}
      expect(last_response).to be_ok
    end

    it "should be OK with shot_at" do
      post '/api/v1/item/initiate', {:user_id=>@user.id, :extension=>".jpg", :access_token=>@token, :shot_at=>1411803465}
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

    it "should not be OK if file_hash conflicts" do
      post '/api/v1/item/initiate', {:user_id=>@user.id, :extension=>".jpg", :access_token=>@token, :file_hash=>"abc"}
      expect(last_response).to be_ok
      post '/api/v1/item/initiate', {:user_id=>@user.id, :extension=>".jpg", :access_token=>@token, :file_hash=>"abc"}
      expect(last_response).not_to be_ok
    end

    it "should be OK even if file_hash conflicts with deleted item" do
      post '/api/v1/item/initiate', {:user_id=>@user.id, :extension=>".jpg", :access_token=>@token, :file_hash=>"abc"}
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      delete '/api/v1/item', {:item_id=>result['item_id'], :access_token=>@token}
      expect(last_response).to be_ok
      post '/api/v1/item/initiate', {:user_id=>@user.id, :extension=>".jpg", :access_token=>@token, :file_hash=>"abc"}
      expect(last_response).to be_ok
    end

  end

  after do
    @access_token.destroy if @access_token
  end

end
