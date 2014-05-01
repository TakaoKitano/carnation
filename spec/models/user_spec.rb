require File.dirname(__FILE__) + '/../spec_helper'
require 'models'

describe User do

  before do
    user = User.find(:email=>"testtest@chikaku.com")
    user.destroy if user
    @user = User.create(:email=>"testtest@chikaku.com")
  end

  it "can create new item with the given user" do
    item = Item.create(:user_id=>@user.id, :extension=>".jpg")
    @user.add_item(item)
    expect(item).not_to be nil
    expect(item.id).to eq(@user.items[0].id)
    expect(item.user_id).to eq(@user.id)
  end

  it "can create a viewer with the given user" do
    viewer = @user.create_viewer("testviewer")
    expect(viewer.id).to eq(@user.viewers[0].id)
    expect(viewer.user_id).to eq(@user.id)
  end

  it "can create a group with the given user" do
    group = @user.create_group("testgroup1")
    expect(group.id).to  eq(@user.groups[0].id)
    expect(group.user_id).to eq(@user.id)
    group.destroy
  end

  it "can create a group and a viewer with the given user" do

    viewer1 = @user.create_viewer("testviewer1")
    viewer2 = @user.create_viewer("testviewer2")
    group = @user.create_group("testgroup1")

    expect(group.viewers.length).to eq(0)
    group.add_viewer(viewer1)
    expect(group.viewers.length).to eq(1)
    group.add_viewer(viewer2)
    expect(group.viewers.length).to eq(2)

    group.remove_all_viewers
    group.remove_all_users
    group.destroy
    viewer1.destroy
    viewer2.destroy
  end

  after do
    @user.destroy if @user
  end

end
