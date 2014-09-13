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
task :tests do
  sh 'bundle exec rspec -c spec/*'
end

namespace :resque do
  desc 'start resque worker process'
  task :start do
    sh 'bundle exec ruby launch_resque_worker.rb &'
  end

  desc 'stop resque worker process'
  task :stop do
    sh "kill -15 `cat log/resque.pid`"
  end
end

namespace :server do
  desc 'start unicorn server'
  task :start do
    sh 'bundle exec unicorn -c unicorn.rb -D'
  end

  desc 'stop unicorn server'
  task :stop do
    sh "cat log/unicorn.pid | xargs kill -QUIT"
  end
end

Rake::PackageTask.new("magoch_server", :noversion) do |t|
  t.package_dir = "build"
  t.package_files.include("**/*")
  t.package_files.exclude("README.md", "conf/**/*", "scripts/**/*", "spec/**/*", "doc/**/*", "log/**/*", "db/**/*", "migrate/**/*",  "vendor/**/*", "build/**/*")
  t.need_tar = true
end

namespace :docker do
  desc 'build docker image'
  task :build do
    Rake::Task["package"].invoke
    gitrev = `git rev-parse --short HEAD`
    sh "sudo docker build --rm=true -t chikaku/carnation ."
    image = `sudo docker images -q | head -1 | tr '\n' ' '`
    sh "sudo docker tag #{image} chikaku/carnation:#{gitrev}"
  end

  desc 'push docker images'
  task :push do
    sh 'sudo docker login --username=chikaku --email=tkitano@chikaku.com --password=Qds0h43CRTdFYwbpce6M'
    sh 'sudo docker push chikaku/carnation'
  end
end

