require 'sequel'
require 'mysql2'
require 'json'
require 'digest/sha2'
require 'rack/oauth2'
require 'securerandom' 
require 'date' 
require 'net/https'
require 'uri'
require 'benchmark'
require 'open-uri'
require 'RMagick'
require 'filemagic'
require 'exiftool'
require 'streamio-ffmpeg'
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

  def can_create_user()
    return true if self.role == User::ROLE[:admin]
    return true if self.role == User::ROLE[:signup]
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

  def self.create_derivatives(item_id)
    p "#{item_id}:create_derivatives"
    item = Item.find(:id=>item_id)
    return nil unless item

    #
    # get lock
    #
    p "#{item_id}:getting DLM lock"
    lock = $DLM.lock("create_derivatives:#{item_id}", 5 * 60 * 1000) # 5 minutes
    if not lock 
      p "#{item_id}: could not get DLM lock"
      return nil
    end

    s3obj = $bucket.objects[item.path + item.extension]
    tmpfile = Tempfile.new(['item', item.extension])
    begin
      p "#{item_id}:downloading item from S3"
      s3obj.read { |chunk|
        tmpfile.write(chunk)
        tmpfile.flush
      }
      p "#{item.id}:getting mime_type"
      mime_type = FileMagic.new(:mime_type).file(tmpfile.path)
      if mime_type.start_with?("image")
        p "#{item.id}:creating image derivatives"
        item.create_image_derivatives(tmpfile.path, mime_type)
      elsif mime_type.start_with?("video")
        p "#{item.id}:creating video derivatives"
        item.create_video_derivatives(tmpfile.path, mime_type)
      end
    rescue
      p "#{item.id}:error while reading S3 object"
    ensure
      tmpfile.close
      tmpfile.unlink
      $DLM.unlock(lock)
    end
  end

  def create_image_derivatives(filepath, mime_type)
    original = Magick::Image.read(filepath).first.auto_orient
    return unless original

    begin
      timestr = original.get_exif_by_entry('DateTime')[0][1]
      self.created_at = Time.parse(timestr.sub(':', '/').sub(':', '/')).to_i
    rescue
      p '#{self.id}:could not get exif DateTime'
    end

    p "#{self.id}:calling Derivative.generate_derivaties"
    result = Derivative.generate_derivatives(self.id, original)

    self.width = original.columns
    self.height = original.rows
    self.duration = 0
    self.filesize = File.size(filepath)
    self.mime_type = mime_type
    self.status = Item::STATUS[:active] if result
    self.save

  end

  def create_video_derivatives(filepath, mime_type)
    movie = FFMPEG::Movie.new(filepath)
    return unless movie


    p "width=" + movie.width.to_s
    p "height="+ movie.height.to_s
    p "duration=" + movie.duration.to_s
    rotation = 0
    e = Exiftool.new(filepath)
    if e
      rotation = e.to_hash[:rotation]
      p "rotation=" + rotation.to_s if rotation
    end 
    begin
      tmpfile = Tempfile.new(['screenshot', '.png'])
      seeksec = [[0, movie.duration-1].max, 3].min
      movie.screenshot(tmpfile.path, {:seek_time=>seeksec, :resolution=>"#{movie.width}x#{movie.height}"})
      original = Magick::Image.read(tmpfile.path).first
      if (rotation && rotation != 0)
        original.rotate!(rotation)
      end
      raise "error" unless original
      result = Derivative.generate_derivatives(self.id, original)
      self.width = movie.width
      self.height = movie.height
      self.duration = movie.duration
      self.filesize = movie.size
      self.mime_type = mime_type
      self.status = Item::STATUS[:active] if result
      self.save

    rescue
      p "#{self.id}:error while creating screenshot"

    ensure
      tmpfile.close
      tmpfile.unlink
    end

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
    begin
      s3obj = $bucket.objects[self.path + self.extension]
      ps = AWS::S3::PresignV4.new(s3obj)
      uri = ps.presign(method_symbol, :expires=>Time.now.to_i+28800,:secure=>true, :signature_version=>:v4)
    rescue
      p "#{self.item_id}:error when generating presigned_url for derivative"
      uri = ""
    end
    uri.to_s
  end

  def after_create
    super
    self.path = self.item.path + "_" + sprintf("%02d", self.index)
    self.save
  end

  def self.generate_derivatives(item_id, original)
    result = true
    begin
      p "#{item_id}:generating medium"
      image = original.resize_to_fit(1920, 1080)
      derivative = Derivative.find_or_create(:item_id=>item_id, :index=>1)
      result = derivative.store_and_upload_file(image, "medium")
    rescue
      p "#{item_id}:error while generating medium image"
      result = false
    ensure
      if image
        image.destroy!
      end
      if not result
        derivative.destroy
      end
    end

    begin
      p "#{item_id}:generating thumbnail"
      image = original.resize_to_fill(100,100)
      derivative = Derivative.find_or_create(:item_id=>item_id, :index=>2)
      result = derivative.store_and_upload_file(image, "thumbnail")
    rescue
      p "#{item_id}:error while generating thumbnail image"
      result = false
    ensure
      if image
        image.destroy!
      end
      if not result
        derivative.destroy
      end
    end
    return result
  end

  def store_and_upload_file(image, name)
    p "#{self.item_id}:store_and_upload_file #{name}"
    result = true
    tmpfile = Tempfile.new(['derivatives', '.jpg'])
    filepath = tmpfile.path
    begin
      p "#{self.item_id}:creating tempfile"
      image.format = 'JPEG'
      image.write(filepath) 

      begin
	p "#{self.item_id}:updating DB"
	self.path = self.item.path + "_" + sprintf("%02d", self.index)
	self.name = name
	self.extension = ".jpg"
	self.width = image.columns
	self.height = image.rows
	self.duration = 0
	self.status = STATUS[:active]
	self.filesize = File.size(filepath)
	self.mime_type = "image/jpeg"
	self.save
      rescue
        p "#{self.item_id}:error while saving to DB"
      end

      begin
	p "#{self.item_id}:uploading to S3"
	$bucket.objects[self.path + self.extension].write(:file => filepath)
      rescue
        p "#{self.item_id}:error while uploading to DB"
      end

    rescue
      p "#{self.item_id}:error in store_and_upload_file"
      result = false
    ensure
      p "#{self.item_id}:removing tmpfile"
      tmpfile.close
      tmpfile.unlink
    end
    return result
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

