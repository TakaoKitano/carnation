$LOAD_PATH.push('./lib')
$LOAD_PATH.push('.')
require "sinatra/base"
require 'models'
require 'rack/oauth2'
require 'carnation'
require 'token'
