Sequel.migration do
  up do
    add_column :accesstokens, :refresh_token, String
    add_index  :accesstokens, :refresh_token
  end

  down do
    drop_column :accesstokens, :refresh_token
    drop_index  :accesstokens, :refresh_token
  end
end
