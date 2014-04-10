
def create_tables(db)

  db.drop_table?:derivatives
  db.drop_table?:viewer_like_items
  db.drop_table?:groups_viewers
  db.drop_table?:items
  db.drop_table?:access_tokens
  db.drop_table?:viewers
  db.drop_table?:clients
  db.drop_table?:groups_users
  db.drop_table?:groups
  db.drop_table?:users

  db.create_table :users, :engine=>:InnoDB do
    primary_key :id
    String      :name
    String      :email, :unique=>true, :null=>false, :index=>true
    String      :password_hash
    String      :password_salt
    Integer     :role
    TimeStamp   :created_at
    TimeStamp   :updated_at
  end

  db.create_table :groups, :engine=>:InnoDB do
    primary_key :id
    String      :name
    foreign_key :user_id, :users, :key=>:id, :null=>false
    TimeStamp   :created_at
    TimeStamp   :updated_at
  end

  db.create_join_table(
    {:user_id=>:users, :group_id=>:groups}, 
    {:name=>:groups_users}
  )

  db.create_table :clients, :engine=>:InnoDB do
    primary_key :id
    String      :appid, :unique=>true, :index=>true
    String      :secret
    TimeStamp   :created_at
    TimeStamp   :updated_at
  end

  db.create_table :viewers, :engine=>:InnoDB do
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

  db.create_table :items, :engine=>:InnoDB do
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

  db.create_table :derivatives, :engine=>:InnoDB do
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

  db.create_join_table(
    {:viewer_id=>:viewers, :group_id=>:groups}, 
    {:name=>:groups_viewers}
  )

  db.create_join_table(
    {:viewer_id=>:viewers, :item_id=>:items}, 
    {:name=>:viewer_like_items}
  )

  db.create_table :access_tokens, :engine=>:InnoDB do
    String      :token,       :primary_key=>true
    foreign_key :user_id,     :users, :null=>true
    foreign_key :viewer_id,   :viewers,  :null=>true
    String      :scope       
    TimeStamp   :expires_at
    TimeStamp   :created_at
  end

end

require './models'
def create_builtin_users
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

  user = User.new("test001@chikaku.com", "___test001___","mago")
  user.role = $DB_USER_ROLE[:common]
  user.save

  client = Client.create(:appid=>"6052d5885f9c2a12c09ef90f815225d3",:secret=>"f6af879a7db8bfbe183e08c1a68e9035")
  user.create_viewer("testviewer", client)
  user.create_group("testgroup")
  

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
end

