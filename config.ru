libdir = File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
appdir = File.join(File.dirname(__FILE__), 'app')
$LOAD_PATH.unshift(appdir) unless $LOAD_PATH.include?(appdir)

require 'token'
require 'carnation'

class Webtest < Sinatra::Base
  
  get '/webtest/*' do
    send_file File.join(File.expand_path(File.dirname(__FILE__)), '..', request.path_info)
  end

end

run Rack::Cascade.new [Webtest, Token, Carnation]

