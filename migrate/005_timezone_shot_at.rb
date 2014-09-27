Sequel.migration do
  up do
    add_column :items, :timezone, Integer
    add_column :items, :shot_at, Integer
    add_column :users, :timezone, Integer
    add_column :viewers, :timezone, Integer
  end

  down do
    drop_column :items, :timezone
    drop_column :items, :shot_at
    drop_column :users, :timezone
    drop_column :viewers, :timezone
  end
end
