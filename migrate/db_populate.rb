require './models'

User.create('admin', 'mago', 'admin@chikaku.com').save
User.create('user1', 'mago', 'user1@chikaku.com').save
User.create('user2', 'mago', 'user2@chikaku.com').save
User.create('user3', 'mago', 'user3@chikaku.com').save
User.create('user4', 'mago', 'user4@chikaku.com').save
User.create('user5', 'mago', 'user5@chikaku.com').save

user1 = User.where(:name => 'user1').first
AccessToken.create(user1.id).save
group1 = Group.create('group1', user1).save
group1.add_user(user1)

Item.create(user1.id, "http://chikaku.com/user1.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image01.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image02.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image03.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image04.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image05.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image06.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image07.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image08.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image09.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image10.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image11.jpg", 0).save
Item.create(user1.id, "http://chikaku.com/user1image12.jpg", 0).save

user2 = User.where(:name => 'user2').first
AccessToken.create(user2.id).save
group2 = Group.create('group2', user2).save
group2.add_user(user2)
group2.add_user(user1)

Item.create(user2.id, "http://chikaku.com/user2image00.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image01.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image02.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image03.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image04.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image05.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image06.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image07.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image08.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image09.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image10.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image11.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image12.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image13.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image14.jpg", 0).save
Item.create(user2.id, "http://chikaku.com/user2image15.jpg", 0).save

#
# for admin
#
client = Client.new()
  client.appid = '0a0c9b87622def4da5801edd7e013b4d'
  client.secret = 'd1572d8cd46913630dfc56f481db818b'
client.save

#
# for appuser
#
client = Client.new()
  client.appid = 'e3a5cde0f20a94559691364eb5fb8bff'
  client.secret =  '116dd4b3a92a17453df0a5ae83e5e640'
client.save

#
# for stb1
#
client = Client.new()
  client.appid = 'b42584ed7da85e97b353d8cbffce10e5'
  client.secret =  '318ce0279c6334eeeef529af90a9813b'
client.save
stb = Stb.create("stb1", client.id)
stb.user_id = User.where(:name => 'user1').first.id
stb.save

#
# for stb2
#
client = Client.new()
  client.appid = 'ffff4ed7da85e97b353d8cbffce10e5'
  client.secret =  'ffffe0279c6334eeeef529af90a9813b'
client.save
stb = Stb.create("stb2", client.id)
stb.user_id = User.where(:name => 'user2').first.id
stb.save
