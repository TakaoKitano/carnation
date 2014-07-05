$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

def create_alpha_users
  #
  # create alpha user data
  #
  user = User.create(:email=>"nahofujino@yahoo.co.jp", :name=>"nahofujino", :password=>"XmOyoRmf2nXkoZUwE4zKjUFOOaIMIL9N", :role=>User::ROLE[:common])
  client = Client.create(:appid=>"o5xxmjnVUWuYWwEIMHudAOTVcEFEmegV", :secret=>"j8WOk5CV3tSmIIy3eXKqTXMlGE6bC4Qn")
  viewer = user.create_viewer("nahofujino_viewer", client)
  group = user.create_group("hanofujino_group")
  group.add_viewer(viewer)

  user = User.create(:email=>"aishibata.test@gmail.com", :name=>"aishibata", :password=>"MKMUJ374cGzS0Ri6rBNcd0bfHAsyHAAj", :role=>User::ROLE[:common])
  client = Client.create(:appid=>"i86alxPDYJjTJBlJoR5yLy6YcBooB9zM", :secret=>"ReUqlm7bxEaFfhnsYp2NGgIGZpss7wyD")
  viewer = user.create_viewer("aishibata_viewer", client)
  group = user.create_group("aishibata_group")
  group.add_viewer(viewer)

  user = User.create(:email=>"takakookamura.test@gmail.com", :name=>"takakookamura", :password=>"mHtL94hbkRfSMqjVXndhg5ujSL8xo2BQ", :role=>User::ROLE[:common])
  client = Client.create(:appid=>"whwxLBmk5fmHayAJGr9QkCVys3n8rF4a", :secret=>"fexBv7syUgVK1zEbji2qaovF3Uq3qH5t")
  viewer = user.create_viewer("takakookamura_viewer", client)
  group = user.create_group("takaokookamura_group")
  group.add_viewer(viewer)

  user = User.create(:email=>"ohyama@omoro.co.jp", :name=>"ohyamaomoro", :password=>"C2o8LcSrqkCdyMbKjXeVaQHcPuzp4aQK", :role=>User::ROLE[:common])
  client = Client.create(:appid=>"r4UHuaXXA4HmtfnLrzj7lKvr32rRUwSy", :secret=>"9yEqWOn2f0Zv9RWsLclXyvtAtQxQObqo")
  viewer = user.create_viewer("ohyama_omoro_viewer", client)
  group = user.create_group("ohyama_omoro_group")
  group.add_viewer(viewer)
end

puts "creating alpha user accounts"
create_alpha_users
