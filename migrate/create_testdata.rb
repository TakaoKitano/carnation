require './models'

User.generate('user1', 'mago', 'user1@chikaku.com').save
User.generate('user2', 'mago', 'user2@chikaku.com').save
User.generate('user3', 'mago', 'user3@chikaku.com').save

user1 = User.where(:name => 'user1').first
group1 = Group.generate('group1', user1).save
group1.add_user(user1)

15.times do 
  item = Item.generate(user1.id, ".jpg").save.set_path
  Derivative.generate(item.id, ".jpg", "thumbnail").save.set_path
  Derivative.generate(item.id, ".jpg", "medium").save.set_path
end

user2 = User.where(:name => 'user2').first
group2 = Group.generate('group2', user2).save
group2.add_user(user2)
group2.add_user(user1)

15.times do 
  item = Item.generate(user2.id, ".jpg").save.set_path
  Derivative.generate(item.id, ".jpg", "thumbnail").save.set_path
  Derivative.generate(item.id, ".jpg", "medium").save.set_path
end

user3 = User.where(:name => 'user3').first
group3 = Group.generate('group3', user3).save
group3.add_user(user3)

15.times do 
  item = Item.generate(user3.id, ".jpg").save.set_path
  Derivative.generate(item.id, ".jpg", "thumbnail").save.set_path
  Derivative.generate(item.id, ".jpg", "medium").save.set_path
end

#
# create stb1 which can see both user1 and user2
#
client = Client.new()
  client.appid = 'b42584ed7da85e97b353d8cbffce10e5'
  client.secret =  '318ce0279c6334eeeef529af90a9813b'
client.save
stb = Stb.generate("stb1", client.id)
stb.user_id = User.where(:name => 'user1').first.id
stb.save

#
# create stb2 which can both user1 and user2
#
client = Client.new()
  client.appid = 'ffff4ed7da85e97b353d8cbffce10e5'
  client.secret =  'ffffe0279c6334eeeef529af90a9813b'
client.save
stb = Stb.generate("stb2", client.id)
stb.user_id = User.where(:name => 'user2').first.id
stb.save

#
# create stb3 which only see user3
#
client = Client.new()
  client.appid = 'eeeeeed7da85e97b3d3d8cbffce10ee'
  client.secret =  'eeeee0279c6334edeef529af90a981ee'
client.save
stb = Stb.generate("stb3", client.id)
stb.user_id = User.where(:name => 'user3').first.id
stb.save
