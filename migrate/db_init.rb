$LOAD_PATH.push('./lib')
$LOAD_PATH.push('.')
require './migrate/db_schema'
require './migrate/create_builtin_users.rb'
require './migrate/create_testdata.rb'
