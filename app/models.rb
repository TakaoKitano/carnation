require 'sequel'
require 'mysql2'
require 'json'
require 'digest/sha1'
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
  one_to_many :devices
  one_to_many :events
  one_to_one :profile
  def initialize(values={})
    super
    self.role = values[:role] || ROLE[:common] 
    self.status = STATUS[:created]
    self.timezone = CarnationConfig.default_timezone
    self.created_at = Time.now.to_i
  end

  def before_destroy
    #
    # remove all items this user owns
    #
    Item.where(:user_id=>self.id).destroy()
    Viewer.where(:user_id=>self.id).destroy()
    self.remove_all_groups
    Group.where(:user_id=>self.id).destroy()
    AccessToken.where(:user_id=>self.id).destroy()
    Device.where(:user_id=>self.id).destroy()
    Event.where(:user_id=>self.id).destroy()
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

# migrate/003_create_table_devices.rb
#
#    create_table(:devices, :ignore_index_errors=>true, :engine => 'InnoDB', :charset=>'utf8') do
#      foreign_key :user_id, :users, :null=>false, :key=>[:id]
#      String      :deviceid
#      Integer     :devicetype
#      Integer     :created_at
#      Integer     :updated_at
#      unique      [:user_id, :deviceid]
#      index       :user_id
#    end
class Device < Sequel::Model(:devices)
  TYPE = { :ios => 1, :android => 2, :windows => 3 }
  many_to_one :user
  def initialize(values={})
    super
    self.created_at = Time.now.to_i
    self.updated_at = self.created_at
  end

  def before_update
    self.updated_at = Time.now.to_i
  end

  def push_notification(param)
    require 'net/https'
    require 'uri'
    uri = URI.parse('https://api.parse.com/1/push')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request["X-Parse-Application-Id"] = CarnationConfig.parse_application_id
    request["X-Parse-REST-API-Key"] = CarnationConfig.parse_rest_api_key
    request["Content-Type"] = "application/json"
    message = param[:message] || "message from magochannel"
    data = { "where"=>{ "installationId"=>self.deviceid}, 
             "data" =>{ "alert"     => message,
                        "sound"     => "default",
                        "badge"     => param[:badge],
                        "viewer_id" => param[:viewer_id],
                        "item_id"   => param[:item_id] } }
    request.body = data.to_json
    response = http.request(request)
    p response, response.body
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
    self.timezone = CarnationConfig.default_timezone
    self.created_at = Time.now.to_i
  end

  def extended_hash
    h = self.to_hash
    client = Client.find(:id=>self.client_id)
    if client
      h[:credentials] = client.to_hash
    end
    return h
  end

  def before_destroy
    self.remove_all_items
    self.remove_all_groups
    Profile.where(:viewer_id=>self.id).destroy()
    ViewerLike.where(:viewer_id=>self.id).destroy()
    AccessToken.where(:viewer_id=>self.id).destroy()
    super
  end

  def after_destroy
    super
    Client.where(:id=>self.client_id).destroy()
  end

  def do_like(item)

    user = User.find(:id=>item.user_id)
    return nil if not user
    #
    # create or find a event, then update
    #
    fPushRequired = false
    event = Event.where(:user_id=>user.id, :event_type=>1, :viewer_id=>self.id).last
    if not event or event.retrieved or event.updated_at < Time.now.to_i - 3600
      event = Event.create(:user_id=>user.id, :event_type=>1, :viewer_id=>self.id).save()
      fPushRequired = true
      CarnationConfig.logger.info "new event created"
      CarnationConfig.logger.info event.to_hash
    else
      CarnationConfig.logger.info "updating existing event"
      CarnationConfig.logger.info event.to_hash
    end
    return nil if not event
    r = ViewerLike.create(:event_id=>event.id, :viewer_id=>self.id, :item_id=>item.id)
    CarnationConfig.logger.info "created ViewerLike record"
    CarnationConfig.logger.info r.to_hash
    event.updated_at = Time.new.to_i
    event.save()

    #
    # old code to be removed eventually
    #
    #r = ViewerLikeItem.find_or_create(:viewer_id=>self.id, :item_id=>item.id)
    #return nil if not r
    #p r.to_hash
    #r.count = 0 if not r.count
    #r.count = r.count + 1
    #r.save()

    #
    # push notification
    #
    if fPushRequired
      count = Event.where(:user_id=>user.id, :retrieved=>false).count
      CarnationConfig.logger.info "events to be retrieved count=#{count}"

      user.devices.each do |d|
        CarnationConfig.logger.info "sending notification from viewer_id:#{self.id} for item_id:#{item.id} to device:#{d.deviceid}"
        d.push_notification(:badge=>count, :message=>"ご実家がお気に入りをつけました！", :viewer_id=>self.id, :item_id=>item.id)
      end 
    end
    return r
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

class Event < Sequel::Model(:events)
  def initialize(values={})
    super
    self.created_at = Time.now.to_i
    self.updated_at = self.created_at
  end
  def before_destroy
    ViewerLike.where(:event_id=>self.id).destroy()
  end
end

class ViewerLike < Sequel::Model(:viewer_likes)
  def initialize(values={})
    super
    self.created_at = Time.now.to_i
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

  #def before_update
  #  self.updated_at = Time.now.to_i
  #end

  def after_create
    super
    self.path = sprintf("%08d", self.user_id) + "/" + sprintf("%08d", self.id)
    self.save()
  end

  def before_destroy
    Derivative.where(:item_id=>self.id).destroy()
    ViewerLike.where(:item_id=>self.id).destroy()
    self.remove_all_viewers
    super
  end

  def to_result_hash(options={})
    result = self.to_hash
    if options[:suppress_urls_if_deleted] and self.status == STATUS[:deleted]
      result[:url] = nil
    else
      result[:url] = self.presigned_url(:get)
    end
    result[:liked_by] = ViewerLike.where(:item_id=>self.id).group_and_count(:viewer_id).all.map do |r|
      {:viewer_id=>r[:viewer_id], :count=>r[:count]}
    end
    result[:derivatives] = self.derivatives.map do |d|
      h = d.to_hash
      if options[:suppress_urls_if_deleted] and self.status == STATUS[:deleted]
        h[:url] = nil
      else
        h[:url] = d.presigned_url(:get)
      end
      h
    end
    result
  end

  def presigned_url(method_symbol)
    begin
      s3obj = CarnationConfig.s3bucket.objects[self.path + self.extension]
      ps = AWS::S3::PresignV4.new(s3obj)
      uri = ps.presign(method_symbol, :expires=>Time.now.to_i+28800,:secure=>true, :signature_version=>:v4)
    rescue
      CarnationConfig.logger.info "#{self.id}:error when generating presigned_url"
      uri = ""
    end
    uri.to_s
  end

  def self.create_derivatives(item_id)
    CarnationConfig.logger.info "#{item_id}:Item.create_derivatives"

    item = Item.find(:id=>item_id)
    return false unless item

    if item.status == Item::STATUS[:deleted]
      CarnationConfig.logger.info "#{item_id}:could not create derivatives for a deleted item"
      return false
    end

    #
    # get lock
    #
    CarnationConfig.logger.info "#{item_id}:getting DLM lock"
    lock = CarnationConfig.dlm.lock("create_derivatives:#{item_id}", 5 * 60 * 1000) # 5 minutes
    if not lock 
      CarnationConfig.logger.info "#{item_id}: could not get DLM lock"
      return false
    end

    result = false
    begin
      #
      # download the file from S3 to a tempfile
      # 
      tmpfile = Tempfile.new(['item', item.extension])
      CarnationConfig.logger.info "#{item_id}:downloading item from S3"
      s3obj = CarnationConfig.s3bucket.objects[item.path + item.extension]
      s3obj.read { |chunk|
        tmpfile.write(chunk)
        tmpfile.flush
      }
      CarnationConfig.logger.info "#{item.id}:item downloaded path=#{tmpfile.path}"
      CarnationConfig.logger.info "#{item.id}:item downloaded size=#{tmpfile.size}"
      digest = Digest::SHA1.file(tmpfile).hexdigest
      CarnationConfig.logger.info "#{item.id}:sha1sum of downloaded s3 file=#{digest}"
      
      if item.file_hash
        CarnationConfig.logger.info "#{item.id}:file_hash=#{item.file_hash}"
        if item.file_hash != digest
          CarnationConfig.logger.info "#{item.id}:error file_hash unmatch"
          return false
        end
      else
        CarnationConfig.logger.info "#{item.id}:no file_hash"
        item.file_hash = digest
      end

      #
      # create image or video derivatives
      # 
      CarnationConfig.logger.info "#{item.id}:getting mime_type"
      mime_type = FileMagic.new(:mime_type).file(tmpfile.path)
      if mime_type.start_with?("image")
        CarnationConfig.logger.info "#{item.id}:calling create_image_derivatives"
        result = item.create_image_derivatives(tmpfile.path, mime_type)
      elsif mime_type.start_with?("video")
        CarnationConfig.logger.info "#{item.id}:calling create_video_derivatives"
        result = item.create_video_derivatives(tmpfile.path, mime_type)
      end
    rescue
      CarnationConfig.logger.info "#{item.id}:error while creating derivatives"
      result = false
    ensure
      tmpfile.close if tmpfile
      tmpfile.unlink if tmpfile
      CarnationConfig.dlm.unlock(lock)
    end
    CarnationConfig.logger.info "#{item_id}:create_derivatives returns #{result}"
    return result
  end

  def create_image_derivatives(filepath, mime_type)
    CarnationConfig.logger.info "#{self.id}:creating image derivatives"
    original = Magick::Image.read(filepath).first

    orientation = original.get_exif_by_entry('Orientation')[0][1].to_i
    if orientation == 1
      rotation = 0
    elsif orientation == 3
      rotation = 180
    elsif orientation == 6
      rotation = 90
    elsif orientation == 8
      rotation = 270
    else
      rotation = 0
    end
    CarnationConfig.logger.info "#{self.id}:rotation=#{rotation}"
    
    original = original.auto_orient
    return false unless original

    #
    # calculate shot_at from exif and timezone
    #
    if not self.shot_at
      diff = self.timezone ? self.timezone * 3600 : 0
      begin
        timestr = original.get_exif_by_entry('DateTime')[0][1]
        epoch = Time.parse(timestr.sub(':', '/').sub(':', '/')).to_i
        CarnationConfig.logger.info "#{self.id}:epoch from exif = #{epoch}"
        CarnationConfig.logger.info "#{self.id}:shot_at = epoch - #{diff}"
        self.shot_at = epoch - diff
      rescue
        CarnationConfig.logger.info "#{self.id}:(not fatal)could not get exif DateTime"
        self.shot_at = self.created_at # last resort
      end
    else
      CarnationConfig.logger.info "#{self.id}:shot_at exists"
    end

    result = Derivative.generate_derivatives(self.id, original)
    CarnationConfig.logger.info "#{self.id}:saving item..."

    begin
      self.width = original.columns
      self.height = original.rows
      self.duration = 0
      self.filesize = File.size(filepath)
      self.mime_type = mime_type
      self.rotation = rotation
      if result
        self.status = Item::STATUS[:active]
        self.updated_at = Time.now.to_i
      end
      self.save()
    rescue
      CarnationConfig.logger.info "#{self.id}:item save error, file_hash conflict"
    end

    CarnationConfig.logger.info "#{self.id}:create_image_derivatives returns #{result}"
    return result
  end

  def create_video_derivatives(filepath, mime_type)
    CarnationConfig.logger.info "#{self.id}:creating video derivatives"
    movie = FFMPEG::Movie.new(filepath)
    return unless movie

    result = false
    CarnationConfig.logger.info "#{self.id}: width=#{movie.width} height=#{movie.height} duration=#{movie.duration}"
    rotation = 0
    exif = Exiftool.new(filepath)
    if exif
      rotation = exif.to_hash[:rotation]
      CarnationConfig.logger.info "#{self.id}:rotation=#{rotation}" if rotation
    end 

    begin
      tmpfile = Tempfile.new(['screenshot', '.png'])
      seeksec = [[0, movie.duration-1].max, 3].min
      movie.screenshot(tmpfile.path, {:seek_time=>seeksec, :resolution=>"#{movie.width}x#{movie.height}"})
      original = Magick::Image.read(tmpfile.path).first
      if original
        original.rotate!(rotation) if (rotation && rotation != 0)
        result = Derivative.generate_derivatives(self.id, original)
        begin
          self.width = movie.width
          self.height = movie.height
          self.duration = movie.duration
          self.filesize = movie.size
          self.mime_type = mime_type
          self.rotation = rotation
          if result
            self.status = Item::STATUS[:active] 
          end
          if not self.shot_at
            self.shot_at = self.created_at
            self.updated_at = Time.now.to_i
          end
          self.save()
        rescue
          CarnationConfig.logger.info "#{self.id}:item save error, file_hash conflict"
          result = false
        end
      else
        CarnationConfig.logger.info "#{self.id}:item failed to read the screenshot image"
        result = false
      end

    rescue
      CarnationConfig.logger.info "#{self.id}:error while creating screenshot"
      result = false
    ensure
      tmpfile.close
      tmpfile.unlink
    end
    return result
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
      s3obj = CarnationConfig.s3bucket.objects[self.path + self.extension]
      ps = AWS::S3::PresignV4.new(s3obj)
      uri = ps.presign(method_symbol, :expires=>Time.now.to_i+28800,:secure=>true, :signature_version=>:v4)
    rescue
      CarnationConfig.logger.info "#{self.item_id}:error when generating presigned_url for derivative"
      uri = ""
    end
    uri.to_s
  end

  def after_create
    super
    self.path = self.item.path + "_" + sprintf("%02d", self.index)
    self.save()
  end

  def self.generate_derivatives(item_id, original)
    result = true
    begin
      CarnationConfig.logger.info "#{item_id}:generating medium"
      image = original.resize_to_fit(1920, 1080)
      derivative = Derivative.find_or_create(:item_id=>item_id, :index=>1)
      result = derivative.store_and_upload_file(image, "medium")
    rescue
      CarnationConfig.logger.info "#{item_id}:error while generating medium image"
      result = false
    ensure
      if image
        image.destroy!
      end
      if not result
        CarnationConfig.logger.info "#{item_id}:deleting derivative"
        derivative.destroy
      end
    end

    begin
      CarnationConfig.logger.info "#{item_id}:generating thumbnail"
      image = original.resize_to_fill(100,100)
      derivative = Derivative.find_or_create(:item_id=>item_id, :index=>2)
      result = derivative.store_and_upload_file(image, "thumbnail")
    rescue
      CarnationConfig.logger.info "#{item_id}:error while generating thumbnail image"
      result = false
    ensure
      if image
        image.destroy!
      end
      if not result
        CarnationConfig.logger.info "#{item_id}:deleting derivative"
        derivative.destroy
      end
    end
    
    CarnationConfig.logger.info "#{item_id}:generate_derivatives returns #{result}"
    return result
  end

  def store_and_upload_file(image, name)
    CarnationConfig.logger.info "#{self.item_id}:store_and_upload_file #{name}"
    result = true
    begin
      CarnationConfig.logger.info "#{self.item_id}:creating tempfile"
      tmpfile = Tempfile.new(['derivatives', '.jpg'])
      filepath = tmpfile.path
      image.format = 'JPEG'
      image.write(filepath) 

      begin
        CarnationConfig.logger.info "#{self.item_id}:updating DB"
        self.path = self.item.path + "_" + sprintf("%02d", self.index)
        self.name = name
        self.extension = ".jpg"
        self.width = image.columns
        self.height = image.rows
        self.duration = 0
        self.status = STATUS[:active]
        self.filesize = File.size(filepath)
        self.mime_type = "image/jpeg"
        self.save()
      rescue
        CarnationConfig.logger.info "#{self.item_id}:error while saving to DB"
        result = false
      end

      if result
        begin
          CarnationConfig.logger.info "#{self.item_id}:uploading to S3"
          CarnationConfig.s3bucket.objects[self.path + self.extension].write(:file => filepath)
        rescue
          CarnationConfig.logger.info "#{self.item_id}:error while uploading to S3"
          result = false
        end
      end

    rescue
      CarnationConfig.logger.info "#{self.item_id}:error in store_and_upload_file"
      result = false
    ensure
      CarnationConfig.logger.info "#{self.item_id}:removing tmpfile"
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

