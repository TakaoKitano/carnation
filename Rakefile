desc 'create mysql account and database'
task :sqlinit do
  sh 'mysql -u root -p <migrate/initialize_database.sql'
end

desc 'database one time initialization'
task :dbinit do
  sh "bundle exec ruby migrate/dbinit.rb"
end

desc 'put test data into the database'
task :testdata do
  sh "bundle exec ruby migrate/testdata.rb"
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
    sh 'bundle exec resque worker -c resque/resque.rc >resque/worker.log &'
  end

  desc 'stop resque worker process'
  task :stop do
    sh "kill -9 `cat resque/resque.pid`"
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
