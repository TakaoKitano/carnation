Sequel.migration do
  up do
    add_column :items, :mime_type, String
    add_column :derivatives, :mime_type, String
  end

  down do
    drop_column :items, :mime_type
    drop_column :derivatives, :mime_type
  end
end
