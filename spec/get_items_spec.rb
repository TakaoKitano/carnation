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

  after do
    @access_token.destroy if @access_token
  end

end
