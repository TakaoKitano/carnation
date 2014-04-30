desc 'database one time initialization'
task :dbinit do
  system 'mysql -u root -p <migrate/initialize_database.sql'
  system 'bundle exec ruby migrate/dbinit.rb'
end

desc 'start test server'
task :rackup do
  system 'bundle exec rackup'
end

desc 'test spec/*'
task :test do
  system 'bundle exec rspec -c spec/*'
end

namespace :resque do
  desc 'start resque worker process'
  task :start do
    system 'bundle exec resque worker -c resque/resque.rc >resque/worker.log &'
  end

  desc 'stop resque worker process'
  task :stop do
    system "kill -9 `cat resque/resque.pid`"
  end

end
