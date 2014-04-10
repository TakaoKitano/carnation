$LOAD_PATH.push('./lib')
$LOAD_PATH.push('.')
require 'db_config'
require 'migrate/initialize'
require 'testdata'

create_tables($DB)
create_builtin_users
create_testdata
