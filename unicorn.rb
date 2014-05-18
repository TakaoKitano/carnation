@dir = File.expand_path(File.dirname(__FILE__))

worker_processes 1
working_directory @dir

timeout 30

listen "#{@dir}/server/unicorn.sock", :backlog => 64
#listen 9292

pid "#{@dir}/server/unicorn.pid"
stdout_path "#{@dir}/server/unicorn.stdout.log"
stderr_path "#{@dir}/server/unicorn.stderr.log"
