Sequel.migration do
  up do
    create_table(:viewer_likes, :engine=>'InnoDB', :charset=>'utf8') do
      primary_key :id
      Integer :created_at
      foreign_key :event_id, :events, :null=>false, :key=>[:id]
      foreign_key :viewer_id, :viewers, :null=>false, :key=>[:id]
      foreign_key :item_id, :items, :null=>false, :key=>[:id]
      index [:event_id, :viewer_id]
    end
  end

  down do
    drop_table(:viewer_likes)
  end
end
