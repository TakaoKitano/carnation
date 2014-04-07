require './models'

#
# create built-in users
#
admin_user = User.generate('admin',  'mago', 'admin@chikaku.com')
admin_user.role = 3
admin_user.save

signup_user = User.generate('signup', 'mago', 'signup@chikaku.com')
signup_user.role = 2
signup_user.save

default_user = User.generate('default', 'mago', 'default@chikaku.com')
default_user.role = 1
default_user.save


#
# create built-in client credentials
#

#
# for admin
#
client = Client.new()
  client.appid = '0a0c9b87622def4da5801edd7e013b4d'
  client.secret = 'd1572d8cd46913630dfc56f481db818b'
client.save

#
# for application 
#
client = Client.new()
  client.appid = 'e3a5cde0f20a94559691364eb5fb8bff'
  client.secret =  '116dd4b3a92a17453df0a5ae83e5e640'
client.save

