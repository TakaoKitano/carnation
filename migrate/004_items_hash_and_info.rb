Sequel.migration do
  up do
    add_column :items, :file_hash, String, :size=>80, :null=>true, :unique=>true
    add_column :items, :file_info, String, :size=>255, :null=>true
  end

  down do
    drop_column :items, :file_hash
    drop_column :items, :file_info
  end
end
