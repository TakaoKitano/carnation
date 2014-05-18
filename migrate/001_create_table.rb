Sequel.migration do
  up do
    create_table(:clients, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      primary_key :id
      String :appid, :size=>255
      String :secret, :size=>255
      Integer :created_at
      
      index [:appid], :name=>:appid, :unique=>true
      index [:appid]
    end
    
    create_table(:users, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      primary_key :id
      String :email, :size=>255, :null=>false
      String :password_hash, :size=>255
      String :password_salt, :size=>255
      String :name, :size=>255
      Integer :role
      Integer :status
      Integer :created_at
      String :lastname, :size=>255
      String :firstname, :size=>255
      Integer :birth_year
      Integer :birth_month
      Integer :birth_day
      String :phone_number, :size=>255
      String :postal_code, :size=>255
      String :address, :text=>true
      
      index [:email], :name=>:email, :unique=>true
      index [:email]
    end
    
    create_table(:groups, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      primary_key :id
      String :name, :size=>255
      String :description, :size=>255
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      Integer :created_at
      
      index [:user_id]
    end
    
    create_table(:items, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      primary_key :id
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      String :path, :size=>255, :null=>false
      String :extension, :size=>255, :null=>false
      Integer :status
      String :title, :size=>255
      String :description, :size=>255
      Integer :width
      Integer :height
      Integer :duration
      Integer :filesize
      Integer :valid_after
      Integer :created_at, :null=>false
      Integer :updated_at, :null=>false
      
      index [:created_at]
      index [:status]
      index [:updated_at]
      index [:user_id]
      index [:valid_after]
    end
    
    create_table(:viewers, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      primary_key :id
      String :name, :size=>255
      Integer :status
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      foreign_key :client_id, :clients, :null=>false, :key=>[:id]
      String :phone_number, :size=>255
      String :postal_code, :size=>255
      String :address, :text=>true
      Integer :valid_through
      Integer :created_at
      
      index [:client_id]
      index [:user_id]
    end
    
    create_table(:accesstokens, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      String :token, :size=>255, :null=>false
      foreign_key :user_id, :users, :key=>[:id]
      foreign_key :viewer_id, :viewers, :key=>[:id]
      String :scope, :size=>255
      Integer :expires_at
      Integer :created_at
      
      primary_key [:token]
      
      index [:user_id], :name=>:user_id
      index [:viewer_id], :name=>:viewer_id
    end
    
    create_table(:derivatives, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      foreign_key :item_id, :items, :null=>false, :key=>[:id]
      Integer :index, :default=>0, :null=>false
      String :path, :size=>255
      String :extension, :size=>255
      Integer :status
      String :name, :size=>255
      Integer :width
      Integer :height
      Integer :duration
      Integer :filesize
      Integer :created_at
      
      primary_key [:item_id, :index]
      
      index [:item_id]
    end
    
    create_table(:group_users, :ignore_index_errors=>true) do
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      foreign_key :group_id, :groups, :null=>false, :key=>[:id]
      
      primary_key [:user_id, :group_id]
      
      index [:group_id]
      index [:user_id, :group_id]
      index [:user_id]
    end
    
    create_table(:group_viewers, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      foreign_key :viewer_id, :viewers, :null=>false, :key=>[:id]
      foreign_key :group_id, :groups, :null=>false, :key=>[:id]
      
      primary_key [:viewer_id, :group_id]
      
      index [:group_id], :name=>:group_id
      index [:viewer_id, :group_id]
    end
    
    create_table(:profiles, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      primary_key :id
      foreign_key :viewer_id, :viewers, :key=>[:id]
      String :email, :size=>255
      String :name, :size=>255
      String :lastname, :size=>255
      String :firstname, :size=>255
      Integer :birth_year
      Integer :birth_month
      Integer :birth_day
      String :phone_number, :size=>255
      String :postal_code, :size=>255
      String :address, :text=>true
      Integer :created_at
      
      index [:email]
      index [:viewer_id]
    end
    
    create_table(:viewer_like_items, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      foreign_key :viewer_id, :viewers, :null=>false, :key=>[:id]
      foreign_key :item_id, :items, :null=>false, :key=>[:id]
      Integer :count
      Integer :updated_at
      
      primary_key [:viewer_id, :item_id]
      
      index [:item_id], :name=>:item_id
      index [:viewer_id, :item_id]
    end
  end

  down do
    drop_table?:derivatives
    drop_table?:viewer_like_items
    drop_table?:items
    drop_table?:accesstokens
    drop_table?:profiles
    drop_table?:group_viewers
    drop_table?:viewers
    drop_table?:clients
    drop_table?:group_users
    drop_table?:groups
    drop_table?:users
  end
end
