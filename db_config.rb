require 'sequel'
require 'mysql2'

$DB = Sequel.connect('mysql://carnation:magomago@localhost/carnationdb')

$DB_USER_ROLE = {
  :admin => 1,
  :default => 2,
  :signup => 3,
  :common => 100
}

$DB_ITEM_STATUS = {
  :initiated => 0,
  :uploaded => 1,
  :trashed => 2,
  :deleted => 3
}

