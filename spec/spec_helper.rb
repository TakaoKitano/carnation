libdir = File.join(File.dirname(__FILE__), '../lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
appdir = File.join(File.dirname(__FILE__), '../app')
$LOAD_PATH.unshift(appdir) unless $LOAD_PATH.include?(appdir)

require 'rack/test'
require 'rspec'
require 'sinatra'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false
