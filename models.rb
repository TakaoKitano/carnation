require 'sequel'
require 'mysql2'
require 'json'
require 'digest/sha2'
require 'rack/oauth2'
require 'securerandom' 
require 'date' 

require './db_config'

class User < Sequel::Model(:users)
  User.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_many :groups, :left_key=>:user_id, :right_key=>:group_id, :join_table=>:groups_users
  one_to_many :items
  one_to_many :viewers
  def initialize(email="", name="", password="")
    super()
    self.email = email
    self.name = name
    self.password_salt =SecureRandom.hex 
    self.password_hash = Digest::SHA256.hexdigest(self.password_salt + password)
  end

  def create_viewer(name, client=nil)
    client = Client.new().save unless client
    viewer = Viewer.new(name, client, self)
    self.add_viewer(viewer)
    return viewer
  end

  def create_group(name)
    group = Group.new(name, self).save
    group.add_user(self)
    self.viewers.each do |viewer|
      group.add_viewer(viewer)
    end
    return group
  end

  def before_destroy
    self.remove_all_groups
    super
  end
end

class Group < Sequel::Model(:groups)
  Group.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_many :users, :left_key=>:group_id, :right_key=>:user_id, :join_table=>:groups_users
  many_to_many :viewers, :left_key=>:group_id, :right_key=>:viewer_id, :join_table=>:groups_viewers
  def initialize(name, owner_user)
    super()
    self.name = name
    self.user_id = owner_user.id
  end
  def before_destroy
      self.remove_all_users
      self.remove_all_viewers
      super
  end
end

class Client < Sequel::Model(:clients)
  Client.plugin :timestamps, :force=>true, :update_on_create=>true
  one_to_one :viewer, :class=>:Viewer # could be nil, if client credintial is used by app user
  def initialize(values={})
    super()
    if values[:appid]
      self.appid = values[:appid]
    else
      self.appid = SecureRandom.hex 
    end
    if values[:secret]
      self.secret = values[:secret]
    else
      self.secret = SecureRandom.hex 
    end
  end
end

class Viewer < Sequel::Model(:viewers)
  Viewer.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_many :items, :left_key=>:viewer_id, :right_key=>:item_id, :join_table=>:viewer_like_items;
  def initialize(name, client, user)
    super()
    self.name = name
    self.client_id = client.id
    self.user_id = user.id
  end
  def before_destroy
      self.remove_all_items
      super
  end
  def after_destroy
      super
      client = Client.where(:id=>self.client_id).first
      client.destroy if client
  end
end

class Item < Sequel::Model(:items)
  Item.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_many :viewers, :left_key=>:item_id, :right_key=>:viewer_id, :join_table=>:viewer_like_items;
  one_to_many :derivatives
  def initialize(user, extension)
    super()
    self.user_id = user.id
    self.extension = extension
    self.status = 0
  end

  def after_create
    super
    self.path = "/" + sprintf("%06d", self.user_id) + "/" + sprintf("%06d", self.id)
    self.save
  end

  def before_destroy
    self.derivatives.each do |derivative|
      derivative.destroy
    end
    self.remove_all_viewers
    super
  end
end


class Derivative < Sequel::Model(:derivatives)
  Derivative.plugin :timestamps, :force=>true, :update_on_create=>true
  many_to_one :item
  def initialize(item, extension, name)
    super()
    self.item_id = item.id
    self.extension = extension
    self.name = name
    self.status = 0
  end

  def after_create
    super
    self.path = self.item.path + "/" + sprintf("%02d", self.id)
    self.save
  end
end

class AccessToken < Sequel::Model(:access_tokens)

  def initialize(viewer_or_user)
      super()
      self.token = SecureRandom.hex 
      if viewer_or_user.instance_of? Viewer
        self.viewer_id = viewer_or_user.id
        self.scope = "read like"
      elsif viewer_or_user.instance_of? User
        self.user_id = viewer_or_user.id
        self.scope = "read create delete"
      end
      now = DateTime.now
      self.created_at = now
      self.expires_at = now + 3 * (24.0/24.0)  # 3 days for now
  end

  def generate_bearer_token
    bearer_token = Rack::OAuth2::AccessToken::Bearer.new(
      :access_token => self.token,
      :user_id => self.user_id,
      :viewer_id => self.viewer_id,
      :scope => self.scope,
      :expires_in => self.expires_at.to_time.to_i - self.created_at.to_time.to_i
    )
  end
end
