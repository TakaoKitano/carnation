#
# check the result of migrate/create_testdata.rb
#
require './models'

describe User do

  before do
    @testuser = User.where(:email=>'testuser@chikaku.com').first
    if not @testuser 
      @testuser = User.new('testuser', 'mago', 'testuser@chikaku.com').save
    end
    Group.where(:user_id=>@testuser.id).all.each do |group|
      group.remove_all_users
      group.remove_all_viewers
      group.destroy
    end
    Item.where(:user_id=>@testuser.id).all.each do |item|
      item.destroy
    end
    Viewer.where(:user_id=>@testuser.id).all.each do |viewer|
      viewer.destroy
    end
  end

  it "can create new item with the given user" do
    user = User.where(:email=>"testuser@chikaku.com").first
    user.should_not == nil
    item = Item.new(user, ".jpg")
    user.add_item(item)
    item.id.should == user.items[0].id
    item.user_id.should == user.id
    # remove_item doesn't work, since user_id is defined as not null
    # in the items schema, you can not disassociate an object from 
    # the current object. Simply destroying the object works fine
    # user.remove_item(item) 
    item.destroy
  end

  it "can create a viewer with the given user" do
    user = User.where(:email=>"testuser@chikaku.com").first
    user.should_not == nil
    client = Client.new().save
    viewer = Viewer.new("testviewer", client, user)
    user.add_viewer(viewer)
    viewer.id.should == user.viewers[0].id
    viewer.user_id.should == user.id
    viewer.destroy
    client.destroy
  end


  it "can create a group with the given user" do
    user = User.where(:email=>"testuser@chikaku.com").first
    user.should_not == nil
    group = Group.new("testgroup1", user).save
    group.add_user(user)
    group.id.should == user.groups[0].id
    group.user_id.should == user.id
    group.remove_all_users
    group.remove_all_viewers
    group.destroy
  end

  it "can create a group and a viewer with the given user" do
    user = User.where(:email=>"testuser@chikaku.com").first
    user.should_not == nil

    client = Client.new().save
    viewer = Viewer.new("testviewer", client, user)
    user.add_viewer(viewer)
    viewer.id.should == user.viewers[0].id
    viewer.user_id.should == user.id

    group = Group.new("testgroup1", user).save

    group.add_user(user)
    group.id.should == user.groups[0].id
    group.user_id.should == user.id

    group.add_viewer(viewer)
    group.viewers.length.should == 1
    group.viewers[0].user_id.should == user.id
    group.viewers[0].id.should == viewer.id

    group.remove_all_viewers
    group.remove_all_users
    group.destroy

    viewer.destroy
    client.destroy

  end

  after do
    Group.where(:user_id=>@testuser.id).all.each do |group|
      group.remove_all_users
      group.remove_all_viewers
      group.destroy
    end
    Item.where(:user_id=>@testuser.id).all.each do |item|
      item.destroy
    end
    Viewer.where(:user_id=>@testuser.id).all.each do |viewer|
      viewer.destroy
    end
    @testuser.remove_all_groups
    @testuser.destroy
  end

end
