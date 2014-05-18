$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'


def create_testdata
  #
  # create test user data
  #
  user = User.create(:email=>"test01@chikaku.com", :name=>"test01",:password=>"dx7PnxqDZ5kr", :role=>User::ROLE[:common])
  client = Client.create(:appid=>"6052d5885f9c2a12c09ef90f815225d3",:secret=>"f6af879a7db8bfbe183e08c1a68e9035")
  viewer = user.create_viewer("test01viewer", client)
  viewer.add_profile(Profile.create({
    :name=>"granma", :lastname=>"kaji", :firstname=>"kenko",
    :birth_year=>1950, :birth_month=>5, :birth_day=>1}))
  viewer.add_profile(Profile.create({
    :name=>"granpa", :lastname=>"kaji", :firstname=>"kenken",
    :birth_year=>1945, :birth_month=>6, :birth_day=>30 }))

  group = user.create_group("test01group")
  user.viewers.each do |viewer|
    group.add_viewer(viewer)
  end

  8.times do |n|
    item = Item.create(:user_id=>user.id, :extension=>".jpg", :title=>"test image")
    item.created_at = Time.now.to_i + n
    item.updated_at = Time.now.to_i + n
    item.valid_after = Time.now.to_i 
    item.status = Item::STATUS[:active]
    item.save
    d = Derivative.create(:item_id=>item.id, :index=>1, :extension=>".png", :name=>"thumbnail")
    d.status = Derivative::STATUS[:active]
    d.save
    d = Derivative.create(:item_id=>item.id, :index=>2, :extension=>".png", :name=>"medium")
    d.status = Derivative::STATUS[:active]
    d.save
  end

  user = User.create(:email=>"test02@chikaku.com", :name=>"test02",:password=>"L8xYqp2cHsAm", :role=>User::ROLE[:common])

  user = User.create(:email=>"test03@chikaku.com", :name=>"test03",:password=>"ozCP4yYi3Zcq", :role=>User::ROLE[:common])
end

puts "creating test data"
create_testdata
