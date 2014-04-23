require './models'

def create_testdata
  #
  # create test user data
  #
  user = User.create_with_email("test01@chikaku.com", "test01","dx7PnxqDZ5kr", User::ROLE[:common])

  client = Client.create(:appid=>"6052d5885f9c2a12c09ef90f815225d3",:secret=>"f6af879a7db8bfbe183e08c1a68e9035")
  viewer = user.create_viewer("test01viewer", client)
  viewer.add_profile(Profile.create(:name=>"granma", :lastname=>"kaji", :firstname=>"ken"))

  group = user.create_group("test01group")
  user.viewers.each do |viewer|
    group.add_viewer(viewer)
  end

  8.times do |n|
    item = Item.create(:user_id=>user.id, :extension=>".jpg", :title=>"test image")
    item.created_at = Time.now.to_i + n
    item.updated_at = Time.now.to_i + n
    item.valid_after = Time.now.to_i 
    item.status = Item::STATUS[:uploaded]
    item.save
    d = Derivative.create(:item_id=>item.id, :index=>1, :extension=>".png", :name=>"thumbnail")
    d.status = Derivative::STATUS[:uploaded]
    d.save
    d = Derivative.create(:item_id=>item.id, :index=>2, :extension=>".png", :name=>"medium")
    d.status = Derivative::STATUS[:uploaded]
    d.save
  end
end
