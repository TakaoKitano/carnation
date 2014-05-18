$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

def create_builtin_users
  #
  # create built-in users
  #
  u = User.new(:email=>"admin@chikaku.com", :name=>"__admin__", :role=>User::ROLE[:admin])
  u.password= "Zh1lINR0H1sw"
  u.save

  u = User.new(:email=>"signup@chikaku.com", :name =>"__signup__", :role =>User::ROLE[:signup])
  u.password= "9TseZTFYR1ol"
  u.save

  u = User.new(:email=>"default@chikaku.com", :name=>"__default__",  :role=>User::ROLE[:default])
  u.password= "6y6bSoTwmKIO"
  u.save

  #
  # client credential used only by admin user
  #
  Client.create(:appid=>'0a0c9b87622def4da5801edd7e013b4d',:secret=>'d1572d8cd46913630dfc56f481db818b')
  #
  # client credentials used by applications (please use one of them)
  #
  Client.create(:appid=>'e3a5cde0f20a94559691364eb5fb8bff',:secret=>'116dd4b3a92a17453df0a5ae83e5e640')
  Client.create(:appid=>'47da3586c65e6bee076d66576ad2d235',:secret=>'c37d77e67676c4a6103107e4b1a120e3')
  Client.create(:appid=>'5b0a7b237b2c69677fa4dfc0c65c1de1',:secret=>'6ae41d7a0f594445e55ce8a818bf799e')
end

p "creating built-in accounts"
create_builtin_users()
