require 'config.rb'

def drop_tables(db)
  db.drop_table?:derivatives
  db.drop_table?:viewer_like_items
  db.drop_table?:items
  db.drop_table?:accesstokens
  db.drop_table?:profiles
  db.drop_table?:group_viewers
  db.drop_table?:viewers
  db.drop_table?:clients
  db.drop_table?:group_users
  db.drop_table?:groups
  db.drop_table?:users
end

def create_tables(db)
  Sequel::MySQL.default_engine = 'InnoDB'
  Sequel::MySQL.default_charset = 'utf8'

  db.create_table(:users) do
    primary_key :id
    String      :email, :null=>false, :unique=>true, :index=>true
    String      :password_hash
    String      :password_salt
    String      :name
    Integer     :role
    Integer     :status
    Integer     :created_at
    String      :lastname
    String      :firstname
    Integer     :birth_year
    Integer     :birth_month
    Integer     :birth_day
    String      :phone_number
    String      :postal_code
    String      :address, :text=>true
  end

  db.create_table(:groups) do
    primary_key :id
    String      :name
    String      :description
    foreign_key :user_id, :users, :key=>:id, :null=>false, :index=>true
    Integer     :created_at
  end

  db.create_table(:group_users) do
    foreign_key :user_id, :users, :null=>false, :index=>true
    foreign_key :group_id, :groups, :null=>false, :index=>true
    primary_key [:user_id, :group_id]
    index [:user_id, :group_id]
  end

  db.create_table(:clients) do
    primary_key :id
    String      :appid, :unique=>true, :index=>true
    String      :secret
    Integer     :created_at
  end

  db.create_table(:viewers) do
    primary_key :id
    String      :name
    Integer     :status
    foreign_key :user_id,  :users, :null=>false, :index=>true
    foreign_key :client_id, :clients, :null=>false, :index=>true
    String      :phone_number
    String      :postal_code
    String      :address, :text=>true
    Integer     :valid_through
    Integer     :created_at
  end

  db.create_table(:profiles) do
    primary_key :id
    foreign_key :viewer_id,   :viewers,:null=>true, :index=>true
    String      :email, :index=>true
    String      :name
    String      :lastname
    String      :firstname
    Integer     :birth_year
    Integer     :birth_month
    Integer     :birth_day
    String      :phone_number
    String      :postal_code
    String      :address, :text=>true
    Integer     :created_at
  end

  db.create_table(:items) do
    primary_key :id
    foreign_key :user_id, :users, :null=>false, :index=>true
    String      :path,        :null=>false
    String      :extension,   :null=>false
    Integer     :status,                    :index=>true    
    String      :title,       :null=>true
    String      :description, :null=>true
    Integer     :width,       :null=>true
    Integer     :height,      :null=>true
    Integer     :duration,    :null=>true
    Integer     :filesize,    :null=>true
    Integer     :valid_after, :null=>true,  :index=>true
    Integer     :created_at,  :null=>false, :index=>true
    Integer     :updated_at,  :null=>false, :index=>true
  end

  db.create_table(:derivatives) do
    foreign_key :item_id, :items, :null=>false, :index=>true
    Integer     :index
    primary_key [:item_id, :index]
    String      :path
    String      :extension  
    Integer     :status     
    String      :name,     :null=>true
    Integer     :width,    :null=>true
    Integer     :height,   :null=>true
    Integer     :duration, :null=>true
    Integer     :filesize, :null=>true
    Integer     :created_at
  end

  db.create_table(:group_viewers) do
    foreign_key :viewer_id, :viewers, :null=>false
    foreign_key :group_id, :groups, :null=>false
    primary_key [:viewer_id, :group_id]
    index [:viewer_id, :group_id]
  end

  db.create_table(:viewer_like_items) do
    foreign_key :viewer_id, :viewers, :null=>false
    foreign_key :item_id, :items, :null=>false
    primary_key [:viewer_id, :item_id]
    index [:viewer_id, :item_id]
    Integer     :count
    Integer     :updated_at
  end


  db.create_table(:accesstokens) do
    String      :token,       :primary_key=>true
    foreign_key :user_id,     :users, :null=>true
    foreign_key :viewer_id,   :viewers,  :null=>true
    String      :scope       
    Integer     :expires_at
    Integer     :created_at
  end

end

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

