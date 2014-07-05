

namespace :db do
  desc 'create mysql account and database'
  task :sqlinit do
    sh 'mysql -u root -p <db/initialize_database.sql'
  end

  desc 'dump mysql data'
  task :backup do
    dbhost = ENV['CARNATION_MYSQL_HOST']
    dbhost = 'localhost' unless dbhost
    sh "mysqldump -ucarnation -paFx4mMHb3z7d6dy carnationdb  -h #{dbhost} --no-create-info >sqldump.sql"
  end

  desc 'restore dumped data'
  task :restore do
    dbhost = ENV['CARNATION_MYSQL_HOST']
    dbhost = 'localhost' unless dbhost
    sh "mysql -ucarnation -paFx4mMHb3z7d6dy carnationdb  -h #{dbhost} <sqldump.sql"
  end

  desc 'drop mysql tables - this blows up all the data, be careful'
  task :drop do
    dbhost = ENV['CARNATION_MYSQL_HOST']
    dbhost = 'localhost' unless dbhost
    sh "mysql -ucarnation -paFx4mMHb3z7d6dy carnationdb  -h #{dbhost} <db/droptables.sql"
  end

  desc 'migrate to the latest state'
  task :migrate do
    dbhost = ENV['CARNATION_MYSQL_HOST']
    dbhost = 'localhost' unless dbhost
    sh "bundle exec sequel -m migrate \"mysql2://carnation:aFx4mMHb3z7d6dy@#{dbhost}/carnationdb\" -E "
  end

  desc 'create built-in accounts'
  task :builtin_accounts do
    sh "bundle exec ruby db/builtin_accounts.rb"
  end

  desc 'create test data'
  task :testdata do
    sh "bundle exec ruby db/testdata.rb"
  end
end

desc 'start test server'
task :rackup do
  sh 'bundle exec rackup'
end

desc "Run all specs in spec directory"
task :spec do
  sh 'bundle exec rspec -c spec/*'
end

namespace :resque do
  desc 'start resque worker process'
  task :start do
    sh 'bundle exec resque worker -c resque/resque.rc'
  end

  desc 'stop resque worker process'
  task :stop do
    sh "kill -9 `cat resque/resque.pid`"
  end
end

namespace :server do
  desc 'start unicorn server'
  task :start do
    sh 'bundle exec unicorn -c unicorn.rb'
  end

  desc 'stop unicorn server'
  task :stop do
    sh "cat server/unicorn.pid | xargs kill -QUIT"
  end
end

