#!/usr/bin/ruby

$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

puts "cleanup accesstokens"
AccessToken.cleanup_expired_tokens()
