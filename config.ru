require "sinatra/base"
require './models'

$LOAD_PATH.push('./lib')
$LOAD_PATH.push('.')
require 'rack/oauth2'

require 'carnation'
require 'token'

class Hello < Sinatra::Base
  get '*' do
    "hello carnation"
  end
end

run Rack::Cascade.new [Token, Carnation, Hello]

