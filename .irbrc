$LOAD_PATH.push('./lib')
$LOAD_PATH.push('.')
require "sinatra/base"
require 'rack/oauth2'
require 'RMagick'
require 'models'
require 'carnation'
require 'token'
