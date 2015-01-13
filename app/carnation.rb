require 'sinatra/base'
require 'rack/oauth2'
require 'models'
require 'date'
require 'json'

class Carnation < Sinatra::Base

  def initialize *args
    super
    @logger = CarnationConfig.logger
  end

  configure :development do 
    Bundler.require :development 
    register Sinatra::Reloader 
    also_reload 'app/models.rb'
    CarnationConfig.logger.info "Sinatra::Reloader registered"
  end 

  helpers do
    def cors_headers
      headers['Access-Control-Allow-Methods'] = '*'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Authorization,X-Requested-With'
    end

    def check_user_id_parameter
      target = User.find(:id=>params[:user_id]) 
      halt(404, "user not found") unless target
      user = User.find(:id=>@token.user_id) if @token.user_id
      halt(404, "user not found") unless user
      if user.id != target.id
        halt(400, "permission denied") unless user.role == User::ROLE[:admin]
      end
      return target.id
    end

    def get_non_zero_length_parameter(sym)
      value = params[sym]
      if value and value.length > 0 
        return value
      end
      return nil
    end

    def check_file_hash_conflict(file_hash, user_id)
      ds = Item.where('status = 0 OR status = 1')
      ds = ds.where(:file_hash => file_hash)
      ds = ds.where(:user_id => user_id)
      if ds.count > 0
        return true 
      end
      return false
    end

    def s3_url(path, method_symbol)
      begin
        s3obj = CarnationConfig.s3bucket.objects[path]
        ps = AWS::S3::PresignV4.new(s3obj)
        url = ps.presign(method_symbol, :expires=>Time.now.to_i+28800,:secure=>true, :signature_version=>:v4)
      rescue
        CarnationConfig.logger.info "error when generating presigned_url"
        url = nil
      end
      return url
    end
  end

  use Rack::OAuth2::Server::Resource::Bearer do |request|
    access_token = request.access_token || request.invalid_token!
    #p "access_token=" + access_token
    token = AccessToken.where(:token => request.access_token).first || request.invalid_token!
    #p "expires_at=" + token.expires_at.to_i.to_s
    #p "       now=" + DateTime.now.to_i.to_s
    if token.expires_at.to_i < DateTime.now.to_i
      CarnationConfig.logger.info "token expired"
      request.invalid_token!
    end
    token
  end

  before do
    @result = {}
    response['Content-Type'] = 'application/json'
    @token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    halt(400, "no access token") unless @token

    @logger.info "#{request.request_method} #{request.path}&#{request.query_string}"
    if @token.user_id
      @logger.info "#{@token.token} user_id:#{@token.user_id}"
    elsif @token.viewer_id
      @logger.info "token:#{@token.token} viewer_id:#{@token.viewer_id}"
    end

    cors_headers
  end

  options '*' do
    cors_headers
    halt 200
  end


  #
  # create a new user
  #
  post '/api/v1/user' do
    halt(400, "access denied") unless @token.user_id
    user = User.find(:id=>@token.user_id) 
    halt(400, "access denied") unless user.can_create_user

    email = params[:email]
    halt(400, "invalid parameter email") unless email and email.length > 0

    password = params[:password]
    halt(400, "invalid parameter password") unless password and password.length > 0

    name = email.sub('@', '_')
    begin
      target = User.create(:email=>params[:email], :password=>params[:password], :name=>name)
    rescue
      halt(400, "sepcified email already exists")
    end

    client = Client.create()
    viewer = target.create_viewer(target.name + "_viewer", client)
    group = target.create_group(target.name + "_group")
    group.add_viewer(viewer)
  
    @result[:id] = target.id
    @result[:email] = target.email
    @result[:name] = target.name
    @result[:password] = params[:password]
    JSON.generate(@result)
  end

  #
  # delete a new user
  #
  delete '/api/v1/user' do
    halt(400, "access denied") unless @token.user_id
    user = User.find(:id=>@token.user_id) 
    halt(400, "access denied") unless user.role == User::ROLE[:admin]
    target = User.find(:id=>params[:user_id]) 
    halt(404, "user not found") unless target

    target.destroy()
  
    @result[:id] = target.id
    @result[:email] = target.email
    @result[:name] = target.name
    JSON.generate(@result)
  end

  #
  # set user attribute
  #
  post '/api/v1/user/attributes' do

    halt(400, "token invalid") unless @token.user_id
    user = User.find(:id=>@token.user_id) 
    halt(400, "token invalid") unless user
    target = User.find(:id=>params[:user_id]) 
    halt(404, "no such user") unless target

    if user.id != target.id and user.role != User::ROLE[:admin]
      halt(400, "access denied")
    end

    email = get_non_zero_length_parameter(:email) 
    name = get_non_zero_length_parameter(:name) 
    timezone = get_non_zero_length_parameter(:timezone) 

    begin
      target.email = email if email 
      target.name = name if name
      target.timezone = timezone.to_i if timezone
      target.save
    rescue
      halt(400, "sepcified email already exists")
    end

    @result[:id] = target.id
    @result[:email] = target.email
    @result[:name] = target.name
    @result[:password] = params[:password]
    JSON.generate(@result)
  end

  #
  # get user info
  #
  get '/api/v1/user' do

    target = User.find(:id=>params[:user_id]) 
    halt(404, "user not found") unless target

    user = User.find(:id=>@token.user_id) if @token.user_id
    if user
      halt(400, "access denied") unless user.can_read_properties_of target
    end
    viewer = Viewer.find(:id=>@token.viewer_id) if @token.viewer_id
    if viewer
      halt(400, "access denied") unless viewer.can_read_properties_of target
    end
    halt(400, "token invalid") unless user or viewer

    @result[:id] = target.id
    @result[:email] = target.email
    @result[:name] = target.name
    @result[:role] = target.role
    @result[:status] = target.status
    @result[:timezone] = target.timezone
    @result[:viewers] = target.viewers.map {|v| v.extended_hash}
    @result[:groups] = Group.where(:user_id=>target.id).all.map {|g| g.to_hash}
    @result[:belong_to_groups] = target.groups.map {|g| g.to_hash}
    JSON.generate(@result)
  end

  #
  # get user id by email
  #
  get '/api/v1/user_by_email' do

    user = User.find(:email=>params[:email])
    halt(404, "user not found") unless user

    @result[:user_id] = user.id
    JSON.generate(@result)
  end

  #
  # post initiate item upload
  #
  post '/api/v1/item/initiate' do

    owner = User.find(:id=>params[:user_id])
    halt(400, "user_id invalid") unless owner

    user = User.find(:id=>@token.user_id)
    halt(400, "invalid token") unless user
    halt(400, "access denied") unless user.can_write_to_item_of owner

    item_id = params[:item_id].to_i
    extension = get_non_zero_length_parameter(:extension) 

    timezone = get_non_zero_length_parameter(:timezone)
    shot_at = get_non_zero_length_parameter(:shot_at)

    if item_id > 0 
      item = Item.find(:id=>item_id)
      halt(400, "item_id invalid") unless item
      halt(400, "access denied") unless owner.id == item.user_id
      halt(400, "access denied") unless user.can_write_to_item_of(owner)
    else 
      halt(400, "extension required") unless extension
      halt(400, "extension invalid") unless extension.index('.') == 0
      file_hash = get_non_zero_length_parameter(:file_hash)
      if file_hash
        @logger.info "file_hash=#{file_hash}"
        halt(400, "file_hash conflict") if check_file_hash_conflict(file_hash, owner.id)
      end
      item = Item.create(:user_id=>owner.id, :extension=>extension)
    end

    item.status = Item::STATUS[:initiated]
    item.title = params[:title]
    item.description = params[:description]
    item.file_info = params[:file_info]
    item.shot_at = shot_at.to_i if shot_at
    if timezone
      item.timezone = timezone.to_i
    else
      item.timezone = owner.timezone
    end

    if file_hash
      item.file_hash = file_hash
    end
    item.save()

    @result[:item_id] = item.id
    @result[:status] = item.status
    @result[:url] = item.presigned_url(:put)
    JSON.generate(@result)
  end

  #
  # initiate upload item with browser
  #
  post '/api/v1/item/initiate_post' do
    owner = User.find(:id=>params[:user_id])
    halt(400, "user_id invalid") unless owner

    user = User.find(:id=>@token.user_id)
    halt(400, "invalid token") unless user
    halt(400, "access denied") unless user.can_write_to_item_of owner

    item_id = params[:item_id].to_i
    extension = get_non_zero_length_parameter(:extension) 

    if item_id > 0 
      item = Item.find(:id=>item_id)
      halt(400, "item_id invalid") unless item
      halt(400, "access denied") unless owner.id == item.user_id
      halt(400, "access denied") unless user.can_write_to_item_of(owner)
    else
      halt(400, "extension required") unless extension
      halt(400, "extension invalid") if extension.index('.') != 0
      file_hash = get_non_zero_length_parameter(:file_hash)
      if file_hash
        halt(400, "file_hash conflict") if check_file_hash_conflict(file_hash, owner.id)
      end
      item = Item.create(:user_id=>owner.id, :extension=>extension)
    end

    item.status = Item::STATUS[:initiated]
    item.timezone = owner.timezone
    item.save()

    form = CarnationConfig.s3bucket.presigned_post(:key => item.path+item.extension)
    require 'erb'
    html = <<-POSTHTML
      <html>
        <body>
          <form action=#{form.url} method='post' enctype='multipart/form-data'>
          <% form.fields.map do |(name, value)| %>
           <input type="hidden" name="<%=name%>" value="<%=value%>"/>
          <% end %>
          <input type="file" name="file"/>
          <p>uploading a file: <br/>
            user name:#{owner.name}<br/> 
            user_id:#{owner.id}<br/>
            item_id:#{item.id}<br/>
            item_path:S3 bucket/#{item.path+item.extension}
          </p>
          <input type="submit" name="upload" value="upload"/>
          </form>
        </body>
      </html>
    POSTHTML
    response['Content-Type'] = 'text/html'
    erb = ERB.new(html)
    erb.result(binding)
  end

  #
  # delete item
  #
  delete '/api/v1/item' do

    user = User.find(:id=>@token.user_id)
    halt(400, "invalid token") unless user

    item_id = params[:item_id].to_i
    item = Item.find(:id=>item_id)
    halt(400, "item_id invalid") unless item
    halt(400, "access denied") unless user.can_write_to(item)

    if item.status == Item::STATUS[:initiated] 
      item.destroy
    else
      item.status = Item::STATUS[:deleted]
      item.updated_at = Time.now.to_i
      item.save()
    end
    @result[:id] = item.id
    @result[:status] = item.status
    JSON.generate(@result)
  end

  #
  # get item
  #
  get '/api/v1/item' do

    user = User.find(:id=>@token.user_id)
    halt(400, "invalid token") unless user

    item = Item.find(:id=>params[:item_id])
    halt(400, "item not found") unless item 
    halt(400, "access denied") unless user.can_read item

    @result = item.to_result_hash(:suppress_urls_if_deleted=>false)
    JSON.generate(@result)
  end

  #
  # re-activate item - undelete item
  #
  put '/api/v1/item/undelete' do

    user = User.find(:id=>@token.user_id)
    halt(400, "invalid token") unless user

    item_id = params[:item_id].to_i
    item = Item.find(:id=>item_id)
    halt(400, "item_id invalid") unless item
    halt(400, "access denied") unless user.can_write_to(item)

    if item.status == Item::STATUS[:deleted] 
      item.status = Item::STATUS[:active]
      item.updated_at = Time.now.to_i
      item.save()
    end
    @result[:id] = item.id
    @result[:status] = item.status
    JSON.generate(@result)
  end

  #
  # activate item - notify item upload completed
  #
  put '/api/v1/item/activate' do

    user = User.find(:id=>@token.user_id)
    halt(400, "invalid token") unless user

    item = Item.find(:id=>params[:item_id])
    halt(400, "item not found") unless item 
    halt(400, "access denied") unless user.can_write_to item

    valid_after = params["valid_after"].to_i
    valid_after = 0 if valid_after <= 0

    item.valid_after = Time.at(Time.now.to_i + valid_after).to_i
    item.save()

    @logger.info "item saved, registering a worker job for item:#{item.id}"
    require 'create_derivatives'
    Resque.enqueue(CreateDerivatives, :item_id=>item.id)

    @result[:id] = item.id
    @result[:status] = item.status
    JSON.generate(@result)
  end


  #
  # get user items
  #
  get '/api/v1/user/items' do

    user = User.find(:id=>@token.user_id) if @token.user_id
    viewer = Viewer.find(:id=>@token.viewer_id) if @token.viewer_id
    owner = User.find(:id=>params[:user_id])
    halt(400, "user_id invalid") unless owner
    if user
      halt(400, "no accesss grant") unless user.can_read_item_of owner
    end
    if viewer
      halt(400, "no accesss grant") unless viewer.can_read_item_of owner
    end

    ds = Item.where(:user_id => owner.id)

    if user
      ignore_status = (params[:ignore_status] == "true")
    else
      ignore_status = false
    end

    if not ignore_status
      if params[:status] && params[:status].length > 0
        status = params[:status].to_i
      else
        status = Item::STATUS[:active]
      end
      ds = ds.where('status = ?', status) 
    end

    ignore_valid_after = (params[:ignore_valid_after] == "true")
    if viewer
      ignore_valid_after = false
    end
    ds = ds.where('valid_after < ?', Time.now.to_i) unless ignore_valid_after

    item_id = params[:item_id].to_i
    if item_id > 0
      ds = ds.where(:id=>item_id)
    else
      greater_than = params["greater_than"].to_i
      if greater_than > 0
        ds = ds.where('id > ?', greater_than)
      end
      less_than = params["less_than"].to_i
      if less_than > 0
        ds = ds.where('id < ?', less_than)
      end
      created_before = params["created_before"].to_i
      if created_before > 0
        ds = ds.where('created_at < ?', created_before)
      end
      created_after = params["created_after"].to_i
      if created_after > 0
        ds = ds.where('created_at > ?', created_after)
      end
      shot_before = params["shot_before"].to_i
      if shot_before > 0
        ds = ds.where('shot_at < ?', shot_before)
      end
      shot_after = params["shot_after"].to_i
      if shot_after > 0
        ds = ds.where('shot_at > ?', shot_after)
      end
      updated_before = params["updated_before"].to_i
      if updated_before > 0
        ds = ds.where('updated_at < ?', updated_before)
      end
      updated_after = params["updated_after"].to_i
      if updated_after > 0
        ds = ds.where('updated_at > ?', updated_after)
      end
      offset = params["offset"].to_i
      if offset > 0
        ds = ds.offset(offset)
      end
      count = params[:count].to_i
      count = 50 if count == 0
      count = 1000 if count > 1000
      ds = ds.limit(count)

      sort_by = "created_at"
      if params[:order_by] == "updated_at"
        sort_by = "updated_at"
      elsif params[:order_by] == "shot_at"
        sort_by = "shot_at"
      end

      if params[:order] == "desc"
        ds = ds.order(Sequel.desc(sort_by.to_sym))
      else
        ds = ds.order(Sequel.asc(sort_by.to_sym))
      end
    end

    if params[:no_details] == "true"
      output = "minimum"
    elsif params[:no_details] == "false"
      output = "full"
    else
      if "compact" == params[:output] 
        output = "compact"
      elsif "summary" == params[:output] 
        output = "summary"
      elsif "minimum" == params[:output] 
        output = "minimum"
      else
        output = "full"
      end
    end

    # TODO: optimise this loop
    items = []
    ds.all.each do |item|
      if output == "compact"
        items << item.id
      elsif output == "summary"
        items << {:id=>item.id,:status=>item.status, :file_hash=>item.file_hash}
      elsif output == "minimum"
        items << {:id=>item.id}
      else
        if user
          items << item.to_result_hash(:suppress_urls_if_deleted=>false)
        else
          items << item.to_result_hash(:suppress_urls_if_deleted=>true)
        end
      end
    end

    @result[:user_id] = owner.id
    @result[:count] = items.length
    @result[:items] = items
    JSON.generate(@result)
  end

  #
  # get user events
  #
  get '/api/v1/user/events' do
    user_id = check_user_id_parameter
    user = User.find(:id=>user_id) 
    halt(400, "invalid user_id") unless user

    ds = Event.where(:user_id=>user_id)
    event_id = params['event_id'].to_i
    if event_id > 0
      ds = ds.where(:id=>event_id)
    else
      greater_than = params["greater_than"].to_i
      ds = ds.where('id > ?', greater_than) if greater_than > 0
      less_than = params["less_than"].to_i
      ds = ds.where('id < ?', less_than) if less_than > 0

      created_before = params["created_before"].to_i
      ds = ds.where('created_at < ?', created_before) if created_before > 0
      created_after = params["created_after"].to_i
      ds = ds.where('created_at > ?', created_after) if created_after > 0

      updated_before = params["updated_before"].to_i
      ds = ds.where('updated_at < ?', updated_before) if updated_before > 0
      updated_after = params["updated_after"].to_i
      ds = ds.where('updated_at > ?', updated_after) if updated_after > 0

      count = params[:count].to_i
      count = 50 if count == 0
      count = 1000 if count > 1000
      ds = ds.limit(count)

      if params[:order] == "desc"
        ds = ds.order(Sequel.desc(:id))
      else
        ds = ds.order(Sequel.asc(:id))
      end
    end

    # TODO: someday optimise this loop
    events = []
    ds.all do |r|
      h = r.to_hash
      #@logger.info "h = #{h}"
      h[:viewer_name]= Viewer.find(:id=>r.viewer_id).name
      ids = []
      ViewerLike.where(:event_id=>r.id, :viewer_id=>r.viewer_id).group(:item_id).join(:items, :id=>:item_id).all.each do |c| 
        ids << c.item_id if c[:status] == Item::STATUS[:active]
      end
      h[:item_ids] = ids
      h.delete(:user_id) # hide from the output json
      events << h
    end

    # 
    # max_retrieved_id and count
    #
    event = Event.where(:user_id=>user_id, :retrieved=>true).last
    if event
      max_retrieved_id = event.id
    else
      max_retrieved_id = 0
    end
    count = Event.where(:user_id=>user_id, :retrieved=>false).count

    @result[:user_id] = user.id
    @result[:new_count] = count
    @result[:max_retrieved_id] = max_retrieved_id
    @result[:events] = events
    JSON.generate(@result)
  end

  post '/api/v1/user/events/read' do
    user_id = check_user_id_parameter
    user = User.find(:id=>user_id) 
    halt(400, "invalid user_id") unless user

    if params['event_id'] && params['event_id'].length > 0
      ids = params['event_id'].split(',').map{|s| s.to_i}
      Event.where(:user_id=>user_id, :id=>ids).update(:read=>true)
    else
      ids = "all"
      Event.where(:user_id=>user_id).update(:read=>true)
    end
    @result[:user_id] = user_id
    @result[:events] = ids
    JSON.generate(@result)
  end

  post '/api/v1/user/events/unread' do
    user_id = check_user_id_parameter
    user = User.find(:id=>user_id) 
    halt(400, "invalid user_id") unless user

    if params['event_id'] && params['event_id'].length > 0
      ids = params['event_id'].split(',').map{|s| s.to_i}
      Event.where(:user_id=>user_id, :id=>ids).update(:read=>false)
    else
      ids = "all"
      Event.where(:user_id=>user_id).update(:read=>false)
    end
    @result[:user_id] = user_id
    @result[:event] = ids
    JSON.generate(@result)
  end

  post '/api/v1/user/events/retrieved' do
    user_id = check_user_id_parameter
    user = User.find(:id=>user_id) 
    halt(400, "invalid user_id") unless user

    if params['event_id'] && params['event_id'].length > 0
      event_id = params['event_id'].to_i
      Event.where(:user_id=>user_id).where('id <= ?', event_id).update(:retrieved=>true)
      Event.where(:user_id=>user_id).where('id > ?', event_id).update(:retrieved=>false)
    else
      event_id = "all"
      Event.where(:user_id=>user_id).update(:retrieved=>true)
    end

    @result[:user_id] = user_id
    @result[:event_id] = event_id
    JSON.generate(@result)
  end

  get '/api/v1/viewer/users' do
    viewer = Viewer.find(:id=>@token.viewer_id) if @token.viewer_id
    halt(400, "invalid token") unless viewer

    users = []
    viewer.groups.each do |group|
      group.users.each do |user|
        users << {:user_id=>user.id, :name=>user.name}
      end  
    end
    @result[:viewer_id] = viewer.id
    @result[:users] = users
    JSON.generate(@result)
  end

  post '/api/v1/viewer/like' do
    viewer = Viewer.find(:id=>@token.viewer_id) if @token.viewer_id
    halt(400, "invalid token") unless viewer

    item_id = params[:item_id].to_i
    item = Item.find(:id=>item_id) if item_id > 0
    halt(400, "item not found") unless item
    halt(400, "access denied") unless viewer.can_read item 

    r = viewer.do_like(item)
    halt(500, "db error") unless r

    @result[:viewer_id] = viewer.id
    @result[:item_id] = item.id
    @result[:count] = ViewerLike.where(:viewer_id=>viewer.id, :item_id=>item.id).count
    @result[:updated_at] = r.created_at
    JSON.generate(@result)
  end

  get '/api/v1/viewer' do
    viewer_id = params[:viewer_id].to_i
    target = Viewer.find(:id=>viewer_id) if viewer_id > 0
    halt(404, "viewer not found") unless target

    if @token.viewer_id 
      viewer = Viewer.find(:id=>@token.viewer_id)
      halt(400, "token invalid") unless viewer
      halt(400, "access denied") unless viewer.can_read_properties_of target
    end

    if @token.user_id 
      user = User.find(:id=>@token.user_id)
      halt(400, "token incalid") unless user
      halt(400, "access denied") unless user.can_read_properties_of target
    end

    @result = target.to_hash
    @result[:belong_to_groups] = target.groups.map {|g| g.to_hash}
    @result[:profiles] = target.profiles.map{|p| p.to_hash}

    JSON.generate(@result)
  end

  #
  # device registration
  #
  post '/api/v1/user/device' do
    user_id = check_user_id_parameter

    deviceid = params[:deviceid]
    p deviceid
    p deviceid.length
    halt(400, "deviceid required") unless deviceid and deviceid.length > 0
    devicetype = params[:devicetype].to_i
    halt(400, "devietype required") unless devicetype and devicetype > 0

    begin
      device = Device.create(:deviceid=>deviceid, :user_id=>user_id, :devicetype=>devicetype)
    rescue
      halt(400, "deviceid might already exist")
    end
    @result = device.to_hash
    JSON.generate(@result)
  end

  #
  # get devices
  #
  get '/api/v1/user/device' do
    user_id = check_user_id_parameter
    
    ds = Device.where(:user_id=>user_id)
    deviceid = params[:deviceid]
    if deviceid && deviceid.length > 0
      ds = ds.where('deviceid = ?', deviceid)
    end
    devices = ds.all

    @result[:user_id] = user_id
    @result[:count] = devices.length
    @result[:devices] = devices.map {|d| d.to_hash}
    JSON.generate(@result)
  end

  #
  # delete device
  #
  delete '/api/v1/user/device' do
    user_id = check_user_id_parameter

    deviceid = params[:deviceid]
    halt(400, "deviceid required") unless (deviceid && deviceid.length > 0)
    
    device = Device.where(:user_id=>user_id).where('deviceid = ?', deviceid).all[0]
    halt(400, "no such device") unless device
    device.destroy

    @result[:user_id] = user_id
    @result[:deleted] = device.to_hash
    JSON.generate(@result)
  end

  #
  # send a message to device (for testing)
  #
  get '/api/v1/user/device/send' do
    user_id = check_user_id_parameter

    deviceid = params[:deviceid]
    halt(400, "deviceid required") unless (deviceid && deviceid.length > 0)

    device = Device.where(:user_id=>user_id).where('deviceid = ?', deviceid).all[0]
    halt(400, "no such device") unless device

    message = params[:message]
    halt(400, "message required") unless (message && message.length > 0)

    device.push_notification(:message=>message)

    @result[:user_id] = user_id
    @result[:deviceid] = device.deviceid
    @result[:message] = message
    JSON.generate(@result)
  end

  #
  # retrieve a file upload url
  #
  get '/api/v1/uploadurl' do
    if @token.user_id
      user = User.find(:id=>@token.user_id)
      halt(400, "user_id invalid") unless user
      user_or_viewer = "user"
      id = user.id
    elsif  @token.viewer_id
      viewer = Viewer.find(:id=>@token.viewer_id) if @token.viewer_id
      halt(400, "viewer_id invalid") unless viewer
      user_or_viewer = "viewer"
      id = viewer.id
    end

    now = DateTime.now
    filename = now.strftime("%Y_%m_%d_%H_%M_%S.log")
    path = sprintf("log/#{user_or_viewer}/%08d/#{filename}", id)
    @logger.info "path=#{path}"

    url = s3_url(path, :put)
    if not url
      halt(500, "s3 error")
    end

    @result[:path] = path
    @result[:url] = s3_url(path, :put)
    JSON.generate(@result)
  end

  get '/api/*' do
    halt 404,"no such api"
  end
end
