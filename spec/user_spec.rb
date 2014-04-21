#
# check the result of migrate/create_testdata.rb
#
require './models'

describe User do

  before do
    user = User.find_with_email("testtest@chikaku.com")
    user.destroy if user
    @user = User.create_with_email("testtest@chikaku.com", "test", "magomago", User::ROLE[:common])
  end

  it "can create new item with the given user" do
    item = Item.create(:user_id=>@user.id, :extension=>".jpg")
    @user.add_item(item)
    item.id.should == @user.items[0].id
    item.user_id.should == @user.id
    # remove_item doesn't work, since user_id is defined as not null
    # in the items schema, you can not disassociate an object from 
    # the current object. Simply destroying the object works fine
    # user.remove_item(item) 
    item.destroy
  end

  it "can create a viewer with the given user" do
    client = Client.create
    viewer = Viewer.new(:name=>"testviewer", :client_id=>client.id, :user_id=>@user.id)
    @user.add_viewer(viewer)
    viewer.id.should == @user.viewers[0].id
    viewer.user_id.should == @user.id
    viewer.destroy
  end


  it "can create a group with the given user" do
    group = Group.create(:name=>"testgroup1", :user_id=>@user.id)
    group.add_user(@user)
    group.id.should == @user.groups[0].id
    group.user_id.should == @user.id
    group.remove_all_users
    group.remove_all_viewers
    group.destroy
  end

  it "can create a group and a viewer with the given user" do

    client = Client.create
    viewer = Viewer.new(:name=>"testviewer", :client_id=>client.id, :user_id=>@user.id)
    @user.add_viewer(viewer)
    viewer.id.should == @user.viewers[0].id
    viewer.user_id.should == @user.id

    group = Group.new(:name=>"testgroup1", :user_id=>@user.id).save

    group.add_user(@user)
    group.id.should == @user.groups[0].id
    group.user_id.should == @user.id

    group.add_viewer(viewer)
    group.viewers.length.should == 1
    group.viewers[0].user_id.should == @user.id
    group.viewers[0].id.should == viewer.id

    group.remove_all_viewers
    group.remove_all_users
    group.destroy

    viewer.destroy

  end

  after do
    @user.destroy if @user
  end

end
