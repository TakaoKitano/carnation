require './models'

def create_testdata
  #
  # create test user data
  #
  user = User.create_with_email("test01@chikaku.com", "test01","dx7PnxqDZ5kr", User::ROLE[:common])

  client = Client.create(:appid=>"6052d5885f9c2a12c09ef90f815225d3",:secret=>"f6af879a7db8bfbe183e08c1a68e9035")
  user.create_viewer("test01viewer", client)
  user.create_group("test01group")

  15.times do |n|
    item = Item.new(:user_id=>user.id, :extension=>".jpg")
    item.status = Item::STATUS[:uploaded]
    item.save
    derivative = Derivative.new(:item_id=>item.id, :index=>1, :extension=>".jpg", :name=>"thumbnail")
    derivative.status = Item::STATUS[:uploaded]
    derivative.save
    derivative = Derivative.new(:item_id=>item.id, :index=>2, :extension=>".jpg", :name=>"medium")
    derivative.status = Item::STATUS[:uploaded]
    derivative.save
  end
end
