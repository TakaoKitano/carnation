require 'date'
require 'json'

class Api < Sinatra::Base

  configure :development do 
    Bundler.require :development 
    register Sinatra::Reloader 
    also_reload './models.rb'
    p "Sinatra::Reloader registered"
  end 

  use Rack::OAuth2::Server::Resource::Bearer do |request|
    access_token = request.access_token || request.invalid_token!
    p "access_token=" + access_token
    token = AccessToken.where(:token => request.access_token).first || request.invalid_token!
    p "expires_at=" + token.expires_at.to_i.to_s
    p "       now=" + DateTime.now.to_i.to_s
    if token.expires_at.to_i < DateTime.now.to_i
      p "token expired"
      request.invalid_token!
    end
    token
  end

  before do
    @result = {}
    response['Content-Type'] = 'application/json'
    @token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    if @token
      p "access_token:", @token 
    else
      p "no access_token provided"
    end
    halt(400, "no access token") if not @token
  end

  get '/api/v1/user' do
    user = User.find(:id=>@token.user_id) if @token.user_id
    viewer = Viewer.find(:id=>@token.viewer_id) if @token.viewer_id
    halt(400, "no valid token") if not user and not viewer

    if params[:user_id].length > 0
      target = User.find(:id=>params[:user_id]) 
      profile = Profile.find(:id=>target.profile_id) if target
    elsif params[:email].length > 0
      profile = Profile.find(:email=>params[:email]) 
      target = User.find(:profile_id=>profile.id) if profile
    end
    halt(404, "no such user") if not target
    @result[:user_id] = target.id
    @result[:name] = target.name
    @result[:role] = target.role
    @result[:status] = target.status
    @result[:profile] = profile.to_hash
    JSON.generate(@result)
  end

  post '/api/v1/item/initiate' do

    owner = User.find(:id=>params[:user_id])
    halt(400, "user_id invalid") if not owner

    user = User.find(:id=>@token.user_id)
    halt(400, "invalid token") if not user
    halt(400, "access denied") if not user.can_create_item_of owner

    item_id = params[:item_id].to_i
    extension = params[:extension] 

    if item_id > 0 
      item = Item.find(:id=>item_id)
      halt(400, "item_id invalid") if not item
    else 
      halt(400, "extension required") if not extension
      halt(400, "extension invalid") if extension.index('.') != 0
      item = Item.new(:user_id=>owner.id, :extension=>extension)
        item.status = Item::STATUS[:initiated]
        item.title = params[:title]
        item.description = params[:description]
        item.width = params[:width].to_i
        item.height = params[:height].to_i 
        item.duration = params[:duration].to_i
        item.filesize = params[:filesize].to_i
      item.save
    end

    @result[:item_id] = item.id
    @result[:status] = item.status
    @result[:url] = item.presigned_url(:put)
    JSON.generate(@result)
  end

  put '/api/v1/item/uploaded' do

    user = User.find(:id=>@token.user_id)
    halt(400, "invalid token") if not user

    item = Item.find(:id=>params[:item_id])
    halt(400, "item not found") if not item 
    halt(400, "access denied") if not user.can_modify item

    valid_after = params["valid_after"].to_i
    valid_after = 0 if valid_after <= 0

    item.valid_after = Time.at(Time.now.to_i + valid_after).to_i
    item.status = Item::STATUS[:uploaded]
    item.save

    p "item saved, registering a worker job for item:#{item.id}"
    require 'resque_workers'
    Resque.enqueue(CreateDerivatives, :item_id=>item.id)

    @result[:item_id] = item.id
    @result[:status] = item.status
    @result[:path] = item.path
    @result[:extension] = item.extension
    @result[:valid_after] = item.valid_after
    @result[:created_at] = item.created_at
    JSON.generate(@result)
  end


  get '/api/v1/user/images' do

    user = User.find(:id=>@token.user_id) if @token.user_id
    viewer = Viewer.find(:id=>@token.viewer_id) if @token.viewer_id
    owner = User.find(:id=>params[:user_id])
    halt(400, "user_id invalid") if not owner
    if user
      halt(400, "no accesss grant") if not user.can_read_item_of owner
    end
    if viewer
      halt(400, "no accesss grant") if not viewer.can_read_item_of owner
    end

    ds = Item.where(:user_id => owner.id)

    ignore_status = (params[:ignore_status] == "true")
    ignore_valid_after = (params[:ignore_valid_after] == "true")
    if viewer
      ignore_status = false
      ignore_valid_after = false
    end
    if not ignore_status
      ds = ds.where('status = ?', Item::STATUS[:uploaded])
    end
    if not ignore_valid_after
      ds = ds.where('valid_after < ?', Time.now.to_i)
    end

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
      offset = params["offset"].to_i
      if offset > 0
        ds = ds.offset(offset)
      end
      count = params[:count].to_i
      count = 20 if count == 0
      ds = ds.limit(count)
      ds = ds.order_by(:created_at)
    end


    items = []
    ds.all.each do |item|

      liked_by = []
      ViewerLikeItem.where(:item_id=>item.id).all.each do |r|
        liked_by << {:viewer_id=>r.viewer_id, :count=>r.count}
      end

      derivatives = []
      item.derivatives.each do |derivative|
        derivatives << {:index=>derivative.index, 
                        :name=>derivative.name, 
                        :width=>derivative.width, 
                        :height=>derivative.height, 
                        :status=>derivative.status, 
                        :url=>derivative.presigned_url(:get)}
      end
      items << {:id=>item.id, 
                :status=>item.status, 
                :created_at=>item.created_at, 
                :valid_after=>item.valid_after, 
                :url=>item.presigned_url(:get), 
                :liked_by=>liked_by, 
                :derivatives=>derivatives}
    end

    @result[:user_id] = owner.id
    @result[:count] = items.length
    @result[:items] = items
    JSON.generate(@result)
  end

  get '/api/v1/viewer/users' do
    viewer = Viewer.find(:id=>@token.viewer_id) if @token.viewer_id
    halt(400, "invalid token") if not viewer

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
    halt(400, "invalid token") if not viewer

    item_id = params[:item_id].to_i
    item = Item.find(:id=>item_id) if item_id > 0
    halt(400, "item not found") if not item
    halt(400, "access denied") if not viewer.can_read item 

    r = viewer.do_like(item)
    halt(500, "db error") if not r

    @result[:viewer_id] = viewer.id
    @result[:item_id] = item.id
    @result[:count] = r.count
    @result[:updated_at] = r.updated_at
    JSON.generate(@result)
  end

  get '/api/v1/viewer' do
    viewer_id = params[:viewer_id].to_i
    target = Viewer.find(:id=>viewer_id) if viewer_id > 0
    halt(404, "viewer not found") if not target

    if @token.viewer_id 
      viewer = Viewer.find(:id=>@token.viewer_id)
      halt(400, "token invalid") if not viewer
      halt(400, "access denied") if not viewer.can_read_info_of target
    end

    if @token.user_id 
      user = User.find(:id=>@token.user_id)
      halt(400, "token incalid") if not user
      halt(400, "access denied") if not user.can_read_info_of target
    end

    @result = target.to_hash
    @result[:profiles] = target.profiles.map{|p| p.to_hash}

    JSON.generate(@result)
  end

  get '/api/*' do
    halt 404,"no such api"
  end
end
