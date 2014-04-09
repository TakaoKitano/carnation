#
# access_token tests
#
require './models'

describe AccessToken do
  before do
    @user = User.where(:email=>'user1@chikaku.com').first
    @user.should_not nil
    @viewer = Viewer.where(:name=>'viewer1').first
    @viewer.should_not nil
  end

  it "can generate token with the given user" do
    token = AccessToken.new(@user)
    p "token:" + token.token + ", user_id:" + token.user_id.to_s + ", expires_at:" + token.expires_at.to_s + " scope=" + token.scope.to_s
    token.should_not nil
    token.user_id.should == @user.id
    token.token.length.should > 0
    token.viewer_id.should == nil
    token.expires_at.should > token.created_at
    token.scope.split(' ').include?("read").should == true
    token.scope.split(' ').include?("like").should == false
    token.scope.split(' ').include?("create").should == true
    token.scope.split(' ').include?("delete").should == true
  end

  it "can generate bearer token with the given user" do
    token = AccessToken.new(@user)
    bearer_token = token.generate_bearer_token
    bearer_token.access_token.should == token.token
    bearer_token.user_id.should == token.user_id
    bearer_token.viewer_id.should == nil
    bearer_token.scope.should == token.scope
    bearer_token.expires_in.should == (token.expires_at.to_time.to_i - token.created_at.to_time.to_i)
  end

  it "can generate token with the given viewer" do
    token = AccessToken.new(@viewer)
    p "token:" + token.token + ", viewer_id:" + token.viewer_id.to_s + ", expires_at:" + token.expires_at.to_s + " scope=" + token.scope.to_s
    token.should_not nil
    token.user_id.should == nil
    token.token.length.should > 0
    token.viewer_id.should == @viewer.id
    token.expires_at.should > token.created_at
    token.scope.split(' ').include?("read").should == true
    token.scope.split(' ').include?("like").should == true
    token.scope.split(' ').include?("write").should == false
    token.scope.split(' ').include?("delete").should == false
  end

  it "can generate bearer token with the given viewer" do
    token = AccessToken.new(@viewer)
    bearer_token = token.generate_bearer_token
    bearer_token.access_token.should == token.token
    bearer_token.viewer_id.should == token.viewer_id
    bearer_token.user_id.should == nil
    bearer_token.scope.should == token.scope
    bearer_token.expires_in.should == (token.expires_at.to_time.to_i - token.created_at.to_time.to_i)
  end

  after do
    
  end

end
