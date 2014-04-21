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

require './config'

class Profile < Sequel::Model(:profiles)
  many_to_many :viewers, :left_key=>:profile_id, :right_key=>:viewer_id, :join_table=>:viewer_profiles
  def initialize(values={})
    super
    self.created_at = Time.now.to_i
  end
end

class User < Sequel::Model(:users)
  ROLE = { :admin => 1, :default => 2, :signup => 3, :common => 100 }
  STATUS = { :created => 1, :activated => 2, :deactivated => 3 }
  many_to_many :groups, :left_key=>:user_id, :right_key=>:group_id, :join_table=>:group_users
  one_to_many :items
  one_to_many :viewers
  one_to_one :profile, :class=>:Profile
  def initialize(values={})
    super
    self.status = STATUS[:created]
    self.created_at = Time.now.to_i
  end
  
  def self.create_with_email(email, name, password, role)
    profile = Profile.find_or_create(:email=>email)
    return nil if User.find(:profile_id=>profile.id)
    user = User.new(:profile_id=>profile.id, :name=>name, :role=>role)
    user.password(password)
    user.save
  end

  def self.find_with_email(email)
    profile = Profile.find(:email=>email)
    user = User.find(:profile_id=>profile.id) if profile
  end

  def password(password)
    self.password_salt =SecureRandom.hex 
    self.password_hash = Digest::SHA256.hexdigest(self.password_salt + password)
  end

  def create_viewer(name, client=nil)
    client = Client.new().save unless client
    viewer = Viewer.new(:name=>name, :client_id=>client.id, :user_id=>self.id)
    self.add_viewer(viewer)
    return viewer
  end

  def create_group(name)
    group = Group.new(:name=>name, :user_id=>self.id).save
    group.add_user(self)
    self.viewers.each do |viewer|
      group.add_viewer(viewer)
    end
    return group
  end

  def before_destroy
    self.items.each do |item|
      item.require_modification = false
      item.destroy
    end
    self.viewers.each do |viewer|
      viewer.require_modification = false
      viewer.destroy
    end
    self.remove_all_groups
    super
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
  many_to_many :profiles, :left_key=>:viewer_id, :right_key=>:profile_id, :join_table=>:viewer_profiles
  def initialize(values={})
    super
    self.status = STATUS[:created]
    self.valid_through = Time.now.to_i + 3600 * 24 * 365
    self.created_at = Time.now.to_i
  end
  def before_destroy
      self.remove_all_items
      super
  end
  def after_destroy
      super
      client = Client.where(:id=>self.client_id).first
      if client
        client.require_modification = false
        client.destroy
      end
  end
end

class Item < Sequel::Model(:items)
  STATUS = { :initiated => 0, :uploaded => 1, :trashed => 2, :deleted => 3 }
  many_to_many :viewers, :left_key=>:item_id, :right_key=>:viewer_id, :join_table=>:viewer_like_items;
  one_to_many :derivatives
  def initialize(values={})
    super
    self.status = STATUS[:initiated]
    self.created_at = Time.now.to_i
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
      image = Magick::Image.from_blob(f.read)

      #
      # thumbnail image
      # 
      thumbnail = image[0].resize_to_fill(100,100)
      p thumbnail
      thumbnail.format = "PNG"

      derivative = Derivative.find_or_create(:item_id=>item.id, :index=>2)
      derivative.extension = ".png"
      p "path = #{derivative.path}"

      uri = URI::parse(derivative.presigned_url(:put))
      p "put uri= #{uri.to_s}"
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = thumbnail.to_blob
      response = https.request(request)

      p response
      if response.code == "200"
        derivative.name = "thumbnail"
        derivative.width = thumbnail.columns
        derivative.height = thumbnail.rows
        derivative.status = STATUS[:uploaded]
        derivative.save
      end

      #
      # normalized image
      # 
      normal = image[0].resize_to_fit(1920)
      normal.format = "PNG"

      derivative = Derivative.find_or_create(:item_id=>item.id, :index=>1)
      derivative.extension = ".png"

      uri = URI::parse(derivative.presigned_url(:put))
      p "put uri= #{uri.to_s}"
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = normal.to_blob
      response = https.request(request)
      p response
      if response.code == "200"
        derivative.name = "normal"
        derivative.width = normal.columns
        derivative.height = normal.rows
        derivative.status = STATUS[:uploaded]
        derivative.save
      end
      p "normal image saved"
    }
  end
end


class Derivative < Sequel::Model(:derivatives)
  STATUS = { :initiated => 0, :uploaded => 1, :trashed => 2, :deleted => 3 }
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
      self.expires_at = now + 3 * (3600 * 24)  # 3 days for now
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
