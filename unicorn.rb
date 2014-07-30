@dir = File.expand_path(File.dirname(__FILE__))

worker_processes 2
working_directory @dir

timeout 30

listen 9292

pid "#{@dir}/server/unicorn.pid"
stdout_path "#{@dir}/server/unicorn.log"
stderr_path "#{@dir}/server/unicorn.log"
