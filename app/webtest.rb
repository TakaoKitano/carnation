require 'sinatra/base'
require 'resque'
require 'redis'
require 'config.rb'

class Webtest < Sinatra::Base
  configure :development do 
    Bundler.require :development 
    register Sinatra::Reloader 
  end 
  helpers do
    def protected!
      unless authorized?
	response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
	throw(:halt, [401, "Not authorized\n"])
      end
    end
    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      username = "kenken"
      password = "magomago"
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [username, password]
    end
  end
  
  get '/webtest/*' do
    protected!
    send_file File.join(File.expand_path(File.dirname(__FILE__)), request.path_info)
  end


  get '/resque' do
    require 'pp'
    template = <<-TEMPLATE
      <html>
	<head><title>Resque Demo</title></head>
	<body>
	  <p>
	    There are <%= @info[:pending] %> pending and <%= @info[:processed] %> processed jobs across <%= @info[:queues] %> queues.
	  </p>
	</body>
      </html>
    TEMPLATE
    @info = Resque.info
    erb template
  end
end

