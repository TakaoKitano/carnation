require './models'
describe Item do

  before do
    @user = User.find_or_create(:email=>"testuser@chikaku.com") do |user|
      user.email = "testuser@chikaku.com"
    end
    @user.items.each do |item|
      item.destroy
    end
  end

  it "can create an item" do
    item = Item.new(@user, ".jpg")
    @user.add_item(item)

    item.id.should == @user.items[0].id
    item.extension.should == ".jpg"
    item.path.length.should > 8

    derivative = Derivative.new(item, ".png", "thumbnail")
    item.add_derivative(derivative)
    derivative.id.should == item.derivatives[0].id
    derivative.item_id == item.id
    derivative.extension.should == ".png"
    derivative.path.length.should > 8

    derivative = Derivative.new(item, ".jpg", "medium size")
    item.add_derivative(derivative)
    derivative.id.should == item.derivatives[1].id
    derivative.item_id == item.id
    derivative.extension.should == ".jpg"
    derivative.path.length.should > 8

    item.derivatives.length.should == 2
  end

  after do
    @user.items.each do |item|
      item.destroy
    end
    @user.destroy if @user
  end
end
