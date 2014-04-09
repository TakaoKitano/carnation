require './models'
describe Item do

  before do
    @user = User.where(:email=>'testuser@chikaku.com').first
    if not @user 
      @user = User.new('testuser', 'mago', 'testuser@chikaku.com').save
    end
    @user.items.each do |item|
      item.derivatives.each do |derivative|
        derivative.destroy
      end
      item.destroy
    end
  end

  it "can create an item" do
    item = Item.new(@user, ".jpg")
    @user.add_item(item)

    item.id.should == @user.items[0].id
    item.extension.should == ".jpg"
    item.path.length.should > 8
    item.path.index(".jpg").should > 0

    derivative = Derivative.new(item, ".png", "thumbnail")
    item.add_derivative(derivative)
    derivative.id.should == item.derivatives[0].id
    derivative.item_id == item.id
    derivative.extension.should == ".png"
    derivative.path.length.should > 8
    derivative.path.index(".png").should > 0

    derivative = Derivative.new(item, ".jpg", "medium size")
    item.add_derivative(derivative)
    derivative.id.should == item.derivatives[1].id
    derivative.item_id == item.id
    derivative.extension.should == ".jpg"
    p "derivative.path=", derivative.path
    derivative.path.length.should > 8
    derivative.path.index(".jpg").should > 0

    item.derivatives.length.should == 2
  end

  after do
    @user.items.each do |item|
      item.derivatives.each do |derivative|
        derivative.destroy
      end
      item.destroy
    end
    @user.destroy
  end

end
