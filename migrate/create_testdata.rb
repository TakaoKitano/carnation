require './models'


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

group = Group.new('group1', user).save
group.add_user(user)
group.add_viewer(viewer)

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

group = Group.new('group2', user).save
group.add_user(user)
group.add_viewer(viewer)

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

group = Group.new('group3', user).save
group.add_user(user)
group.add_viewer(viewer)
