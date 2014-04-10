require './models'

def create_testdata
  #
  # setup user1
  #
  user = User.new('user1@chikaku.com', 'user1', 'mago').save

  15.times do 
    item = Item.new(user, ".jpg").save
    Derivative.new(item, ".jpg", "thumbnail").save
    Derivative.new(item, ".jpg", "medium").save
  end
  viewer = user.create_viewer("viewer1")
  group = user.create_group("group1")


  #
  # setup user2
  #
  user = User.new('user2@chikaku.com', 'user2', 'mago').save

  15.times do 
    item = Item.new(user, ".jpg").save
    Derivative.new(item, ".jpg", "thumbnail").save
    Derivative.new(item, ".jpg", "medium").save
  end
  viewer = user.create_viewer("viewer2")
  group = user.create_group("group2")

  #
  # setup user3
  #
  user = User.new('user3@chikaku.com', 'user3', 'mago').save

  15.times do 
    item = Item.new(user, ".jpg").save
    Derivative.new(item, ".jpg", "thumbnail").save
    Derivative.new(item, ".jpg", "medium").save
  end

  viewer = user.create_viewer("viewer3")
  group = user.create_group("group3")

end
