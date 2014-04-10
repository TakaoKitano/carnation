require 'db_config'

$DB.drop_table?:derivatives
$DB.drop_table?:viewer_like_items
$DB.drop_table?:groups_viewers
$DB.drop_table?:items
$DB.drop_table?:access_tokens
$DB.drop_table?:viewers
$DB.drop_table?:clients
$DB.drop_table?:groups_users
$DB.drop_table?:groups
$DB.drop_table?:users

$DB.create_table :users, :engine=>:InnoDB do
  primary_key :id
  String      :name
  String      :email, :unique=>true, :null=>false, :index=>true
  String      :password_hash
  String      :password_salt
  Integer     :role
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :groups, :engine=>:InnoDB do
  primary_key :id
  String      :name
  foreign_key :user_id, :users, :key=>:id, :null=>false
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_join_table(
  {:user_id=>:users, :group_id=>:groups}, 
  {:name=>:groups_users}
)

$DB.create_table :clients, :engine=>:InnoDB do
  primary_key :id
  String      :appid, :unique=>true, :index=>true
  String      :secret
  TimeStamp   :created_at
  TimeStamp   :updated_at
end

$DB.create_table :viewers, :engine=>:InnoDB do
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

$DB.create_join_table(
  {:viewer_id=>:viewers, :group_id=>:groups}, 
  {:name=>:groups_viewers}
)

$DB.create_join_table(
  {:viewer_id=>:viewers, :item_id=>:items}, 
  {:name=>:viewer_like_items}
)

$DB.create_table :access_tokens, :engine=>:InnoDB do
  String      :token,       :primary_key=>true
  foreign_key :user_id,     :users, :null=>true
  foreign_key :viewer_id,   :viewers,  :null=>true
  String      :scope       
  TimeStamp   :expires_at
  TimeStamp   :created_at
end



