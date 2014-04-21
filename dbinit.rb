$LOAD_PATH.push('./lib')
$LOAD_PATH.push('.')
require './config'
require './db_onetime_init'
puts "drop tables..."
drop_tables($DB)
puts "creating tables..."
create_tables($DB)
puts "creating builtin users..."
create_builtin_users
puts "creating test data"
require 'testdata'
create_testdata
