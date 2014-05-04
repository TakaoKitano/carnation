$LOAD_PATH.unshift('./lib')
$LOAD_PATH.unshift('./app')
require "sinatra/base"
require 'rack/oauth2'
require 'RMagick'
require 'models'
require 'carnation'
require 'token'
