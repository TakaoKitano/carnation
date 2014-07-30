#!/usr/bin/ruby

$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

def cleanup_tokens(now)
    AccessToken.where('expires_at < ?', now).all.each do |token|
      p "token for user #{token.user_id}: expires_at #{Time.at(token.expires_at)}" if token.user_id
      p "token for viewer #{token.viewer_id}: expires_at #{Time.at(token.expires_at)}" if token.viewer_id
      token.destroy
    end
end

puts "cleanup tokens"
now = Time.new
p "token expires_at before #{now}: #{now.to_i} will be deleted"
cleanup_tokens(now.to_i)
