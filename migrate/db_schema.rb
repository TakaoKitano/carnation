require './db_connect'

$DB.drop_table?:items
$DB.drop_table?:access_tokens
$DB.drop_table?:stbs
$DB.drop_table?:clients
$DB.drop_table?:groups_users
$DB.drop_table?:groups
$DB.drop_table?:users

$DB.create_table :users do
  primary_key :id
  String      :name
  String      :email
  String      :password_hash
  String      :password_salt
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :groups do
  primary_key :id
  String      :name
  foreign_key :owner_user_id, :users, :key=>:id, :null=>false
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :groups_users do
  primary_key :id
  foreign_key :user_id, :users
  foreign_key :group_id, :groups
end

$DB.create_table :clients do
  primary_key :id
  String      :appid, :unique=>true
  String      :secret
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :stbs do
  primary_key :id
  String      :name
  String      :phone_number
  String      :postal_code
  String      :address, :text=>true
  foreign_key :user_id,  :users, :null=>false
  foreign_key :client_id, :clients, :null=>false
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :items do
  primary_key :id, :type=>Bignum
  foreign_key :user_id, :users, :null=>false
  String      :url
  String      :thumbnail_url
  Integer     :status
  Integer     :type
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :access_tokens do
  String      :token,       :primary_key=>true
  foreign_key :user_id,     :users, :null=>true
  foreign_key :stb_id,      :stbs,  :null=>true
  String      :scope       
  TimeStamp   :expires_at
  TimeStamp   :created_at
end

