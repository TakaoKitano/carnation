require 'sequel'
require 'mysql2'

$DB = Sequel.connect('mysql://carnation:magomago@localhost/carnationdb')

$DB_USER_ROLE = {
  :admin => 1,
  :default => 2,
  :signup => 3,
  :common => 100
}

$DB_USER_STATUS = {
  :created => 1,
  :activated => 2,
  :deactivated => 3
}

$DB_VIEWER_STATUS = {
  :created => 1,
  :activated => 2,
  :deactivated => 3,
}

$DB_ITEM_STATUS = {
  :initiated => 0,
  :uploaded => 1,
  :trashed => 2,
  :deleted => 3
}

require 'aws-sdk'
AWS.config(
  :access_key_id => 'AKIAI2ZSXBHOXAWRFCQA',
  :secret_access_key => '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',
  :region => 'ap-northeast-1')
