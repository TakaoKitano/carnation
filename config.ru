$LOAD_PATH.push('./lib')
$LOAD_PATH.push('.')
require "sinatra/base"
require 'rack/oauth2'
require './models'
require './api_route'
require './token'

class Hello < Sinatra::Base
  get '/hello' do
    "hello carnation"
  end
end


run Rack::Cascade.new [Token, ApiRoute, Hello]

