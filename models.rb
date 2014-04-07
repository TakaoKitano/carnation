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
  def self.generate(name, password, email)
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
  def self.generate(name, owner_user)
    r = Group.new
    r.name = name
    r.owner_user_id = owner_user.id
    return r
  end
end

class Client < Sequel::Model(:clients)
  Client.plugin :timestamps, :force=>true, :update_on_create=>true
  one_to_one :stb, :class=>:Stb
  def self.generate(user=nil)
    r = Client.new
    r.clientid = SecureRandom.hex 
    r.secret = SecureRandom.hex 
    return r
  end
end

class Stb < Sequel::Model(:stbs)
  Stb.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_many :items, :left_key=>:stb_id, :right_key=>:item_id, :join_table=>:stb_like_items;
  def self.generate(name, client_id)
    r = Stb.new
    r.name = name
    r.client_id = client_id
    return r
  end
end

class Item < Sequel::Model(:items)
  Item.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_many :stbs, :left_key=>:item_id, :right_key=>:stb_id, :join_table=>:stb_like_items;
  one_to_many :derivatives
  def self.generate(user_id, extension)
    r = Item.new
    r.user_id = user_id
    r.extension = extension
    r.status = 0
    return r
  end
  
  def set_path
    self.path = "/" + sprintf("%08d", self.user_id) + "/" + sprintf("%08d", self.id) + self.extension
    self.save
  end
end


class Derivative < Sequel::Model(:derivatives)
  Derivative.plugin :timestamps, :force=>true, :update_on_create=>true
  def self.generate(item_id, extension, name)
    r = Derivative.new
    r.item_id = item_id
    r.extension = extension
    r.name = name
    r.status = 0
    return r
  end

  def set_path
    item = Item.where(:id => self.item_id).first
    self.path = "/" + sprintf("%08d", item.user_id) + "/" + sprintf("%08d", self.item_id) + "/" + sprintf("%08d", self.id) + self.extension
    self.save
  end
end

class AccessToken < Sequel::Model(:access_tokens)
  def self.generate(stb_or_user)
    r = AccessToken.new
      r.token = SecureRandom.hex 
      if stb_or_user.instance_of? Stb
        r.stb_id = stb_or_user.id
        r.scope = "read like"
      elsif stb_or_user.instance_of? User
        r.user_id = stb_or_user.id
        r.scope = "read create delete"
      end
      now = DateTime.now
      r.created_at = now
      r.expires_at = now + 3 * (24.0/24.0)  # 3 days for now
    return r
  end

  def generate_bearer_token
    bearer_token = Rack::OAuth2::AccessToken::Bearer.new(
      :access_token => self.token,
      :user_id => self.user_id,
      :stb_id => self.stb_id,
      :scope => self.scope,
      :expires_in => self.expires_at.to_time.to_i - self.created_at.to_time.to_i
    )
  end
end
