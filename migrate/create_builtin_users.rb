require './models'

#
# create built-in users
#
user = User.new("admin@chikaku.com" ,"___admin___", "mago")
user.role = $DB_USER_ROLE[:admin]
user.save

user = User.new("signup@chikaku.com", "___signup___","mago")
user.role = $DB_USER_ROLE[:signup]
user.save

user = User.new("default@chikaku.com", "___default___","mago")
user.role = $DB_USER_ROLE[:default]
user.save

#
# create built-in client credentials
#

#
# for admin
#
Client.create(:appid=>'0a0c9b87622def4da5801edd7e013b4d',:secret=>'d1572d8cd46913630dfc56f481db818b')

#
# for application 
#
Client.create(:appid=>'e3a5cde0f20a94559691364eb5fb8bff',:secret=>'116dd4b3a92a17453df0a5ae83e5e640')

