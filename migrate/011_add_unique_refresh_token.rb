Sequel.migration do
  up do
    alter_table(:accesstokens) do
      add_unique_constraint(:refresh_token, :name=>'unique_refresh_token')
    end
  end

  down do
    alter_table(:accesstokens) do
      drop_index(:refresh_token, :name=>'unique_refresh_token')
    end
  end
end
