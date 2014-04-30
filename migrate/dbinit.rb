$LOAD_PATH.unshift('./lib') unless $LOAD_PATH.include?('./lib')
$LOAD_PATH.unshift('./app') unless $LOAD_PATH.include?('./app')
$LOAD_PATH.unshift('.') unless $LOAD_PATH.include?('.')
require 'db_onetime_init.rb'
puts "drop tables..."
drop_tables($DB)
puts "creating tables..."
create_tables($DB)
puts "creating builtin users..."
create_builtin_users
puts "creating test data"
require 'testdata'
create_testdata
