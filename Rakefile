task :resque do
  p "starting resque worker..."
  system "bundle exec resque work -c='resque/rescue.rc' >resque/worker.log &"
end
