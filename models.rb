require 'sequel'
require 'mysql2'
require 'json'
require 'digest/sha2'
require 'securerandom' 
require 'date' 

require './db_connect'

class User < Sequel::Model(:users)
  User.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_many :groups, :left_key=>:user_id, :right_key=>:group_id, :join_table=>:groups_users
  one_to_many :items
  def self.create(name, password, email)
    r = User.new
    r.name = name
    r.password_salt =SecureRandom.hex 
    r.password_hash = Digest::SHA256.hexdigest(r.password_salt + password)
    r.email = email
    return r
  end
end

class Group < Sequel::Model(:groups)
  Group.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_many :users, :left_key=>:group_id, :right_key=>:user_id, :join_table=>:groups_users
  def self.create(name, owner_user)
    r = Group.new
    r.name = name
    r.owner_user_id = owner_user.id
    return r
  end
end

class Client < Sequel::Model(:clients)
  Client.plugin :timestamps, :force=>true, :update_on_create=>true
  one_to_one :stb, :class=>:Stb
  def self.create(user=nil)
    r = Client.new
    r.clientid = SecureRandom.hex 
    r.secret = SecureRandom.hex 
    return r
  end
end

class Stb < Sequel::Model(:stbs)
  Stb.plugin :timestamps, :force=>true, :update_on_create=>true
  def self.create(name, client_id)
    r = Stb.new
    r.name = name
    r.client_id = client_id
    return r
  end
end

class Item < Sequel::Model(:items)
  Item.plugin :timestamps, :force=>true, :update_on_create=>true
  def self.create(user_id, url, type)
    r = Item.new
    r.user_id = user_id
    r.url = url
    url[url.rindex('.') || url.length] = "_thumb."
    url = url.chop if url.end_with?('.')
    r.thumbnail_url = url
    r.status = 0
    r.type = type
    return r
  end
end

class AccessToken < Sequel::Model(:access_tokens)
  def self.create(user_id, access_list = nil)
    r = AccessToken.new
      r.token = SecureRandom.hex 
      r.user_id = user_id
      if (access_list)
	r.access_list = JSON.generate(access_list)
      else
	r.access_list = "{}"
      end
      now = DateTime.now
      r.created_at = now
      r.expires_at = now + 3 * (24.0/24.0)  # 3 days for now
    return r
  end
end
