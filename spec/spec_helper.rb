libdir = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
appdir = File.join(File.dirname(__FILE__), '..', 'app')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(appdir)
basedir = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift(appdir) unless $LOAD_PATH.include?(basedir)
curdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(curdir) unless $LOAD_PATH.include?(curdir)

require 'rack/test'
require 'rspec'
require 'sinatra'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false
