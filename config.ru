$LOAD_PATH.push('./lib')
$LOAD_PATH.push('.')
require "sinatra/base"
require 'rack/oauth2'
require './models'
require './api'
require './token'
require './post_upload'


run Rack::Cascade.new [Token, PostUpload, Api]

