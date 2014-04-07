require './db_connect'

$DB.drop_table?:derivatives
$DB.drop_table?:stb_like_items
$DB.drop_table?:items
$DB.drop_table?:access_tokens
$DB.drop_table?:stbs
$DB.drop_table?:clients
$DB.drop_table?:groups_users
$DB.drop_table?:groups
$DB.drop_table?:users

$DB.create_table :users, :engine=>:InnoDB do
  primary_key :id
  String      :name
  String      :email
  String      :password_hash
  String      :password_salt
  Integer     :role    # 0:normal, 1:default, 2:signup, 3:admin
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :groups, :engine=>:InnoDB do
  primary_key :id
  String      :name
  foreign_key :owner_user_id, :users, :key=>:id, :null=>false
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :groups_users, :engine=>:InnoDB do
  primary_key :id
  foreign_key :user_id, :users
  foreign_key :group_id, :groups
end

$DB.create_table :clients, :engine=>:InnoDB do
  primary_key :id
  String      :appid, :unique=>true
  String      :secret
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :stbs, :engine=>:InnoDB do
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

$DB.create_table :items, :engine=>:InnoDB do
  primary_key :id
  foreign_key :user_id, :users, :null=>false
  String      :path       
  String      :extension # e.g. ".jpg" ".png" or ".mp4"
  Integer     :status    # 0:initiate, 1:active, 2:inactive, 3:deleted
  String      :name,     :null=>true
  Integer     :width,    :null=>true
  Integer     :height,   :null=>true
  Integer     :duration, :null=>true
  Integer     :filesize, :null=>true
  TimeStamp   :valid_after
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :derivatives, :engine=>:InnoDB do
  primary_key :id
  foreign_key :item_id, :items, :null=>false
  String      :path
  String      :extension  
  Integer     :status     
  String      :name,     :null=>true
  Integer     :width,    :null=>true
  Integer     :height,   :null=>true
  Integer     :duration, :null=>true
  Integer     :filesize, :null=>true
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :stb_like_items, :engine=>:InnoDB do
  primary_key :id
  foreign_key :stb_id, :stbs
  foreign_key :item_id, :items
end

$DB.create_table :access_tokens, :engine=>:InnoDB do
  String      :token,       :primary_key=>true
  foreign_key :user_id,     :users, :null=>true
  foreign_key :stb_id,      :stbs,  :null=>true
  String      :scope       
  TimeStamp   :expires_at
  TimeStamp   :created_at
end



