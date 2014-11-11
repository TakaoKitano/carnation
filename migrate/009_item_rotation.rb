Sequel.migration do
  up do
    add_column :items, :rotation, Integer
  end

  down do
    drop_column :items, :rotation
  end
end
