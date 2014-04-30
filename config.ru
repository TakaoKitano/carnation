libdir = File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
appdir = File.join(File.dirname(__FILE__), 'app')
$LOAD_PATH.unshift(appdir) unless $LOAD_PATH.include?(appdir)
curdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(curdir) unless $LOAD_PATH.include?(curdir)

require 'carnation'
require 'token'
require 'post_upload'
require 'webtest'

run Rack::Cascade.new [Webtest, Token, PostUpload, Carnation]

