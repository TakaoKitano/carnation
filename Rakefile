require 'rake/packagetask'
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
    sh 'bundle exec ruby resque/launch_resque_worker.rb >>resque/worker.log 2>&1 &'
  end

  desc 'stop resque worker process'
  task :stop do
    sh "kill -15 `cat resque/worker.pid`"
  end
end

namespace :server do
  desc 'start unicorn server'
  task :start do
    sh 'bundle exec unicorn -c unicorn.rb -D'
  end

  desc 'stop unicorn server'
  task :stop do
    sh "cat server/unicorn.pid | xargs kill -QUIT"
  end
end

Rake::PackageTask.new("magoch_server", :noversion) do |t|
  t.package_dir = "docker/app"
  t.package_files.exclude("vendor/**/*", "docker/**/*")
  t.package_files.include("**/*")
  t.need_tar = true
end

namespace :docker do
  desc 'build images'
  task :build do
    sh 'cd docker/base && sudo docker build --rm=true -t tkitano/carnation.base .'
    Rake::Task["package"].invoke
    sh 'cd docker/app && sudo docker build --rm=true -t tkitano/carnation.app .'
  end

  desc 'push images'
  task :push do
    sh 'sudo docker login'
    sh 'sudo docker push tkitano/carnation.base'
    sh 'sudo docker push tkitano/carnation.app'
  end
end

