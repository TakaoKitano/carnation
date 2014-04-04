require 'sequel'
require 'mysql2'

$DB = Sequel.connect('mysql://carnation:magomago@localhost/carnationdb')
