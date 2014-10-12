Sequel.migration do
  up do
    create_table(:events, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      primary_key :id
      Integer     :created_at
      Integer     :updated_at
      Integer     :event_type  # 0:system, 1:like 
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      foreign_key :viewer_id, :viewers, :null=>true, :key=>[:id]
      Boolean     :read, :default=>false
      Boolean     :retrieved, :default=>false
      index       [:user_id]
      index       [:created_at]
      index       [:updated_at]
    end
  end
  down do
    drop_table?:events
  end
end
