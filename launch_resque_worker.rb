#!/usr/bin/ruby
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), 'lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), 'app')
$stdout.reopen(File.join(File.expand_path(File.dirname(__FILE__)), 'log/resque.log'), "w")
$stderr.reopen(File.join(File.expand_path(File.dirname(__FILE__)), 'log/resque.log'), "w")

require 'create_derivatives'

worker = Resque::Worker.new("default")
worker.term_timeout = 4.0
worker.term_child = true
worker.run_at_exit_hooks = false
worker_interval = 5
pidfile = File.join(File.expand_path(File.dirname(__FILE__)), './resque.pid')

File.open(pidfile, 'w') { |f| f << worker.pid }
worker.log "Starting resque worker #{worker}"
worker.work(worker_interval)
worker.log "resque worker terminated #{worker}"
