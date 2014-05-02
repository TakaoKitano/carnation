require 'sequel'
require 'mysql2'
require 'json'
require 'digest/sha2'
require 'rack/oauth2'
require 'securerandom' 
require 'date' 
require 'net/https'
require 'uri'
require 'open-uri'
require 'RMagick'

require 'config.rb'

class User < Sequel::Model(:users)
  ROLE = { :admin => 1, :default => 2, :signup => 3, :common => 100 }
  STATUS = { :created => 1, :activated => 2, :deactivated => 3 }
  many_to_many :groups, :left_key=>:user_id, :right_key=>:group_id, :join_table=>:group_users
  one_to_many :items
  one_to_many :viewers
  one_to_one :profile
  def initialize(values={})
    super
    self.role = values[:role] || ROLE[:common] 
    self.status = STATUS[:created]
    self.created_at = Time.now.to_i
  end

  def before_destroy
    #
    # remove all items this user owns
    #
    self.items.each do |item|
      item.require_modification = false
      item.destroy
    end

    #
    # remove all viewers this user owns
    #
    self.viewers.each do |viewer|
      viewer.require_modification = false
      viewer.destroy
    end

    #
    # remove associations of the group this user belongs to 
    #
    self.remove_all_groups

    #
    # remove all groups this user owns
    #
    Group.where(:user_id=>self.id).each do |group|
      group.require_modification = false
      group.destroy
    end

    #
    # remove all access tokens published for this user
    #
    accesstoken = AccessToken.find(:user_id=>self.id)
    if accesstoken
      accestoken.require_modification = false
      accestoken.destroy
    end

    super
  end
  
  def after_destroy
    super
  end

  def password=(password)
    self.password_salt =SecureRandom.hex 
    self.password_hash = Digest::SHA256.hexdigest(self.password_salt + password)
  end

  def create_viewer(name, client=nil)
    client = Client.create() unless client
    viewer = Viewer.create(:name=>name, :client_id=>client.id, :user_id=>self.id)
    self.add_viewer(viewer)
    return viewer
  end

  def create_group(name)
    group = Group.create(:name=>name, :user_id=>self.id)
    self.add_group(group)
    return group
  end

  def can_write_to_item_of(user)
    return false if not user
    return true if self.id == user.id
    return true if self.role == User::ROLE[:admin]
    return false
  end

  def can_read_item_of(user)
    return false if not user

    return true if self.id == user.id
    return true if self.role == User::ROLE[:admin]
    return true if user.role == User::ROLE[:default]
    self.groups.each do |g|
      g.users.each do |u|
        return true if u.id == user.id
      end
    end
    return false
  end

  def can_write_to(item)
    return can_write_to_item_of(User.find(:id=>item.user_id))
  end

  def can_read(item)
    return can_read_item_of(User.find(:id=>item.user_id))
  end

  def can_read_properties_of(target)
    return false if not target
    if target.instance_of? User
      return true if self.id == target.id            # user equals to onwer
      return true if self.role == User::ROLE[:admin] # user is admin
      self.groups.each do |g|
        g.users.each do |u|
          return true if u.id == target.id           # the owner belongs to a group user belongs to
        end
      end
    end
    if target.instance_of? Viewer
      return true if self.id == target.user_id       # user owns the viewer
      return true if self.role == User::ROLE[:admin] # user is admin
      self.groups.each do |g|
        g.viewers.each do |v|
          return true if v.id == target.id           # viewer belongs to a group user belongs to
        end
      end
    end
    if target.instance_of? Group
      return true if self.id == target.user_id       # user owns the group
      return true if self.role == User::ROLE[:admin] # user is admin
      self.groups.each do |g|
        return true if g.id == target.id             # user belongs to the group
      end
    end
    return false
  end

end

class Group < Sequel::Model(:groups)
  many_to_many :users, :left_key=>:group_id, :right_key=>:user_id, :join_table=>:group_users
  many_to_many :viewers, :left_key=>:group_id, :right_key=>:viewer_id, :join_table=>:group_viewers
  def initialize(values={})
    super
    self.created_at = Time.now.to_i
  end
  def before_destroy
      self.remove_all_users
      self.remove_all_viewers
      super
  end
end

class Client < Sequel::Model(:clients)
  one_to_one :viewer, :class=>:Viewer # could be nil, if client credintial is used by app user
  def initialize(values={})
    super
    self.appid = SecureRandom.hex if not values[:appid]
    self.secret = SecureRandom.hex  if not values[:secret]
    self.created_at = Time.now.to_i
  end
end

class Viewer < Sequel::Model(:viewers)
  STATUS = { :created => 1, :activated => 2, :deactivated => 3 }
  many_to_many :items, :left_key=>:viewer_id, :right_key=>:item_id, :join_table=>:viewer_like_items;
  many_to_many :groups, :left_key=>:viewer_id, :right_key=>:group_id, :join_table=>:group_viewers
  one_to_many :profiles
  def initialize(values={})
    super
    self.status = STATUS[:created]
    self.valid_through = Time.now.to_i + 3600 * 24 * 365
    self.created_at = Time.now.to_i
  end

  def before_destroy
    self.remove_all_items
    self.remove_all_groups
    profiles.each do |profile|
      profile.require_modification = false
      profile.destroy
    end
    accesstoken = AccessToken.find(:viewer_id=>self.id)
    if accesstoken
      accestoken.require_modification = false
      accestoken.destroy
    end
    super
  end

  def after_destroy
    super
    client = Client.find(:id=>self.client_id)
    if client
      client.require_modification = false
      client.destroy
    end
  end

  def do_like(item)
    r = ViewerLikeItem.find_or_create(:viewer_id=>self.id, :item_id=>item.id)
    return nil if not r

    r.count = 0 if not r.count
    r.count = r.count + 1
    r.save
  end

  def can_read_item_of(owner)
    return false if not owner
    return true if owner.role == User::ROLE[:default]
    self.groups.each do |g|
      g.users.each do |u|
        return true if u.id == owner.id
      end
    end
    return false
  end

  def can_read(item)
    owner = User.find(:id=>item.user_id)
    return can_read_item_of(owner)
  end

  def can_read_properties_of(target)
    if target.instance_of? Viewer
      viewer = target
      return false if not viewer
      return true if self.id == viewer.id
      #
      # REVIEW: should we allow a viewer to get the information 
      # of another viewer that belongs to the same group ?
      #
      self.groups.each do |g|
        g.viewers.each do |v|
          return true if v.id == viewer.id
        end
      end
    end
    if target.instance_of? User
      user = target
      return false if not user
      return true if self.user_id == user.id
      #
      # REVIEW: should we allow a viewer to get the information 
      # of another user that belongs to the same group ?
      #
      self.groups.each do |g|
        g.users.each do |u|
          return true if u.id == user.id
        end
      end
    end
    if target.instance_of? Group
      group = target
      return false if not group
      self.groups.each do |g|
        return true if g.id == group.id
      end
    end
    return false
  end
end

class Profile < Sequel::Model(:profiles)
  def initialize(values={})
    super
    self.created_at = Time.now.to_i
  end
end

class ViewerLikeItem < Sequel::Model(:viewer_like_items)
  unrestrict_primary_key

  def before_update
    self.updated_at = Time.now.to_i
  end
end

class Item < Sequel::Model(:items)
  STATUS = { :initiated => 0, :active => 1, :deleted => 2 }
  many_to_many :viewers, :left_key=>:item_id, :right_key=>:viewer_id, :join_table=>:viewer_like_items;
  one_to_many :derivatives
  def initialize(values={})
    super
    self.status = STATUS[:initiated]
    self.created_at = Time.now.to_i
    self.updated_at = Time.now.to_i
    self.valid_after = Time.now.to_i + 3600 * 24
  end

  def before_update
    self.updated_at = Time.now.to_i
  end

  def after_create
    super
    self.path = sprintf("%08d", self.user_id) + "/" + sprintf("%08d", self.id)
    self.save
  end

  def before_destroy
    self.derivatives.each do |derivative|
      derivative.require_modification = false
      derivative.destroy
    end
    self.remove_all_viewers
    super
  end

  def to_result_hash
    result = self.to_hash
    result[:url] = self.presigned_url(:get)
    result[:liked_by] = ViewerLikeItem.where(:item_id=>self.id).all.map do |r|
      {:viewer_id=>r.viewer_id, :count=>r.count}
    end
    result[:derivatives] = self.derivatives.map do |d|
      h = d.to_hash
      h[:url] = d.presigned_url(:get)
      h
    end
    result
  end

  def presigned_url(method_symbol)
    s3obj = $bucket.objects[self.path + self.extension]
    ps = AWS::S3::PresignV4.new(s3obj)
    uri = ps.presign(method_symbol, :expires=>Time.now.to_i+28800,:secure=>true, :signature_version=>:v4)
    uri.to_s
  end

  def self.create_and_upload_derivatives(item_id)
    p "create_and_upload_derivatives item_id=#{item_id}"
    item = Item.find(:id=>item_id)
    return nil if not item
    presigned_url =  item.presigned_url(:get)
    open(presigned_url) { |f|
      original = Magick::Image.from_blob(f.read)

      #
      # thumbnail image
      # 
      image = original[0].resize_to_fill(100,100)
      image.format = "PNG"

      derivative = Derivative.find_or_create(:item_id=>item.id, :index=>2)
      derivative.extension = ".png"
      p "path = #{derivative.path}"

      uri = URI::parse(derivative.presigned_url(:put))
      p "put uri= #{uri.to_s}"
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = image.to_blob
      response = https.request(request)

      p response
      if response.code == "200"
        derivative.name = "thumbnail"
        derivative.width = image.columns
        derivative.height = image.rows
        derivative.status = STATUS[:active]
        derivative.save
      end

      #
      # medium size image
      # 
      image = original[0].resize_to_fit(1920)
      image.format = "PNG"

      derivative = Derivative.find_or_create(:item_id=>item.id, :index=>1)
      derivative.extension = ".png"

      uri = URI::parse(derivative.presigned_url(:put))
      p "put uri= #{uri.to_s}"
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = image.to_blob
      response = https.request(request)
      p response
      if response.code == "200"
        derivative.name = "medium"
        derivative.width = image.columns
        derivative.height = image.rows
        derivative.status = STATUS[:active]
        derivative.save
      end
      p "medium image saved"
    }
  end
end


class Derivative < Sequel::Model(:derivatives)
  STATUS = { :initiated => 0, :active => 1, :deleted => 2 }
  many_to_one :item
  unrestrict_primary_key
  def initialize(values={})
    super
    self.status = STATUS[:initiated]
    self.created_at = Time.now.to_i
  end

  def presigned_url(method_symbol)
    s3obj = $bucket.objects[self.path + self.extension]
    ps = AWS::S3::PresignV4.new(s3obj)
    uri = ps.presign(method_symbol, :expires=>Time.now.to_i+28800,:secure=>true, :signature_version=>:v4)
    uri.to_s
  end

  def after_create
    super
    self.path = self.item.path + "_" + sprintf("%02d", self.index)
    self.save
  end
end


class AccessToken < Sequel::Model(:accesstokens)

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
    now = Time.now.to_i
    self.created_at = now
    self.expires_at = now + 1 * (3600 * 24)  # 1 days for now
  end

  def generate_bearer_token
    bearer_token = Rack::OAuth2::AccessToken::Bearer.new(
      :access_token => self.token,
      :user_id => self.user_id,
      :viewer_id => self.viewer_id,
      :scope => self.scope,
      :expires_in => self.expires_at - self.created_at
    )
  end
end

