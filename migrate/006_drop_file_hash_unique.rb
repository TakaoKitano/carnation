Sequel.migration do
  up do
    alter_table(:items) do
      drop_constraint(:file_hash, :type=>:unique)
    end
  end

  down do
    alter_table(:items) do
      add_constraint(:file_hash, :type=>:unique)
    end
  end
end
