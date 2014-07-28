$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')
require 'create_derivatives'

worker = Resque::Worker.new("default")
worker.term_timeout = 4.0
worker.term_child = true
worker.run_at_exit_hooks = false
worker_interval = 5
pidfile = File.join(File.expand_path(File.dirname(__FILE__)), './worker.pid')

File.open(pidfile, 'w') { |f| f << worker.pid }
worker.log "Starting worker #{worker}"
worker.work(worker_interval)
worker.log "worker terminated #{worker}"
