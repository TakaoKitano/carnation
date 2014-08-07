Sequel.migration do
  up do
    create_table(:devices, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
      primary_key :id
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      String      :deviceid
      Integer     :devicetype
      Integer     :created_at
      Integer     :updated_at
      unique      [:user_id, :deviceid]
      index       :user_id
    end
  end
  down do
    drop_table?:devices
  end
end
