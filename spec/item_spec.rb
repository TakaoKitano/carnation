require './models'
describe Item do

  before do
    @user = User.create_with_email("testtest@chikaku.com", "test", "magomago", User::ROLE[:common])
  end

  it "can create an item" do
    item = Item.new(:user_id=>@user.id, :extension=>".jpg")
    @user.add_item(item)

    item.id.should == @user.items[0].id
    item.extension.should == ".jpg"
    item.path.length.should > 8

    derivative = Derivative.new(:item_id=>item.id, :extension=>".png", :name=>"thumbnail")
    item.add_derivative(derivative)
    derivative.id.should == item.derivatives[0].id
    derivative.item_id == item.id
    derivative.extension.should == ".png"
    derivative.path.length.should > 8

    derivative = Derivative.new(:item_id=>item.id, :extension=>".jpg", :name=>"medium size")
    item.add_derivative(derivative)
    derivative.id.should == item.derivatives[1].id
    derivative.item_id == item.id
    derivative.extension.should == ".jpg"
    derivative.path.length.should > 8

    item.derivatives.length.should == 2
  end

  after do
    @user.destroy if @user
  end
end
