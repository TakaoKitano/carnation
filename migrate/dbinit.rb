$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')
require 'database_schema.rb'
puts "drop tables..."
drop_tables($DB)
puts "creating tables..."
create_tables($DB)
puts "creating builtin users..."
create_builtin_users
