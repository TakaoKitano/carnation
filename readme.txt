bundle install --path vendor/bundle
bundle exec ruby migrate/db_init.rb

bundle exec irb 
require './models'

or
 
bundle exec rackup
