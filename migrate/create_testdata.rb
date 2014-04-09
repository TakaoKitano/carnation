require './models'


#
# setup user1
#
user = User.new('user1', 'mago', 'user1@chikaku.com').save

15.times do 
  item = Item.new(user, ".jpg").save
  Derivative.new(item, ".jpg", "thumbnail").save
  Derivative.new(item, ".jpg", "medium").save
end

client = Client.new()
  client.appid = 'b42584ed7da85e97b353d8cbffce10e5'
  client.secret =  '318ce0279c6334eeeef529af90a9813b'
client.save
viewer = Viewer.new("viewer1", client, user).save

group = Group.new('group1', user).save
group.add_user(user)
group.add_viewer(viewer)

#
# setup user2
#
user = User.new('user2', 'mago', 'user2@chikaku.com').save

15.times do 
  item = Item.new(user, ".jpg").save
  Derivative.new(item, ".jpg", "thumbnail").save
  Derivative.new(item, ".jpg", "medium").save
end

client = Client.new()
  client.appid = 'ffff4ed7da85e97b353d8cbffce10e5'
  client.secret =  'ffffe0279c6334eeeef529af90a9813b'
client.save
viewer = Viewer.new("viewer2", client, user).save

group = Group.new('group2', user).save
group.add_user(user)
group.add_viewer(viewer)

#
# setup user3
#
user = User.new('user3', 'mago', 'user3@chikaku.com').save

15.times do 
  item = Item.new(user, ".jpg").save
  Derivative.new(item, ".jpg", "thumbnail").save
  Derivative.new(item, ".jpg", "medium").save
end

client = Client.new()
  client.appid = 'eeeeeed7da85e97b3d3d8cbffce10ee'
  client.secret =  'eeeee0279c6334edeef529af90a981ee'
client.save
viewer = Viewer.new("viewer3", client, user).save

group = Group.new('group3', user).save
group.add_user(user)
group.add_viewer(viewer)
