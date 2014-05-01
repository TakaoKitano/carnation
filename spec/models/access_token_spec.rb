require File.dirname(__FILE__) + '/../spec_helper'
require 'models'

describe AccessToken do

  describe "#new" do
     before do
       @user = User.find(:name=>"test01")
     end

    context "with given user" do
       it "can create a new token" do
         token = AccessToken.new(@user)
         expect(token).not_to be nil
         expect(token.user_id).to eq(@user.id)
         expect(token.viewer_id).to be nil
         expect(token.token.length).to be > 8
       end
       it "the result token can generate bearer token" do
         token = AccessToken.new(@user)
         bearer = token.generate_bearer_token
         expect(bearer).not_to be nil
         expect(bearer.access_token).to eq(token.token)
         expect(bearer.user_id).to eq(@user.id)
         expect(bearer.viewer_id).to be nil
         expect(bearer.scope).to eq(token.scope)
         expect(bearer.expires_in).to eq(token.expires_at - token.created_at)
       end
    end

    context "with given viewer" do
       before do
         @viewer = @user.create_viewer("testviewer")
       end
       it "can create a new token" do
         token = AccessToken.new(@viewer)
         expect(token).not_to be nil
         expect(token.user_id).to be nil
         expect(token.viewer_id).to eq(@viewer.id)
         expect(token.token.length).to be > 8
       end
       it "the result token can generate bearer token" do
         token = AccessToken.new(@viewer)
         bearer = token.generate_bearer_token
         expect(bearer).not_to be nil
         expect(bearer.access_token).to eq(token.token)
         expect(bearer.user_id).to be nil
         expect(bearer.viewer_id).to eq(@viewer.id)
         expect(bearer.scope).to eq(token.scope)
         expect(bearer.expires_in).to eq(token.expires_at - token.created_at)
       end
       after do
         @viewer.destroy if @viewer
       end
    end
    after do
    end
  end
end
