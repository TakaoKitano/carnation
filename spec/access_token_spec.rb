#
# access_token tests
#
require './models'

describe AccessToken do
  before do
    @user = User.where(:name=>'user1').first
    @user.should_not nil
    @stb = Stb.where(:name=>'stb1').first
    @stb.should_not nil
  end

  it "can generate token with the given user" do
    @token = AccessToken.generate(@user)
    p "token:" + @token.token + ", user_id:" + @token.user_id.to_s + ", expires_at:" + @token.expires_at.to_s + " scope=" + @token.scope.to_s
    @token.should_not nil
    @token.token.length.should > 0
    @token.user_id.should == @user.id
    @token.stb_id.should == nil
    @token.expires_at.should > @token.created_at
    @token.scope.split(' ').include?("read").should == true
    @token.scope.split(' ').include?("like").should == false
    @token.scope.split(' ').include?("create").should == true
    @token.scope.split(' ').include?("delete").should == true
  end

  it "can generate token with the given stb" do
    @token = AccessToken.generate(@stb)
    p "token:" + @token.token + ", stb_id:" + @token.stb_id.to_s + ", expires_at:" + @token.expires_at.to_s + " scope=" + @token.scope.to_s
    @token.should_not nil
    @token.token.length.should > 0
    @token.user_id.should == nil
    @token.stb_id.should == @stb.id
    @token.expires_at.should > @token.created_at
    @token.scope.split(' ').include?("read").should == true
    @token.scope.split(' ').include?("like").should == true
    @token.scope.split(' ').include?("write").should == false
    @token.scope.split(' ').include?("delete").should == false
  end

  after do
    
  end

end
