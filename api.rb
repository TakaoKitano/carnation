require 'date'
require 'json'

class Api < Sinatra::Base

  helpers do
    def check_user_resource_availability(owner, user, viewer)
      return true if (user && user.id == owner.id)
      owner.groups.each do |group|
        if user
          group.users.each do |u|
            return true if u.id == user.id
          end
        end
        if viewer
          group.viewers.each do |v|
            return true if v.id == viewer.id
          end
        end
      end
      return false
    end

    def check_item_access(item, viewer)
      user = User.find(:id=>item.user_id)
      return false if not user
      user.groups.each do |group|
        group.viewers.each do |v|
          return true if v.id == viewer.id
        end
      end
      return false
    end
  end

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

  post '/api/v1/item/initiate' do

    user_id = params[:user_id].to_i
    item_id = params[:item_id].to_i
    extension = params[:extension] 

    user = User.find(:id=>user_id)
    halt(400, "user_id invalid") if not user

    caller_user_id = @token.user_id
    halt(400, "user_id unmatch") if user_id != caller_user_id

    if item_id > 0 
      item = Item.find(:id=>item_id)
      halt(400, "item_id invalid") if not item
    else 
      halt(400, "extension required") if not extension
      halt(400, "extension invalid") if extension.index('.') != 0
      item = Item.new(:user_id=>user.id, :extension=>extension)
        item.status = Item::STATUS[:initiated]
        item.name = params[:name]
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

    user_id = params[:user_id].to_i
    item_id = params[:item_id].to_i

    user = User.where(:id=>user_id).first 
    halt(400, "user_id invalid") if not user

    item = Item.where(:id=>item_id).first 
    halt(400, "item_id invalid") if not item 
    halt(400, "user_id invalid") if item.user_id != user_id

    valid_after = params["valid_after"].to_i
    valid_after = 300 if valid_after <= 0

    item.valid_after = Time.at(Time.now.to_i + valid_after).to_i
    item.status = Item::STATUS[:uploaded]
    item.save

    p "item saved"
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
    halt(400, "no accesss grant") if not check_user_resource_availability(owner, user, viewer)

    ds = Item.where(:user_id => owner.id)
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
        if derivative.status == Derivative::STATUS[:uploaded]
          derivatives << {:index=>derivative.index, 
                          :name=>derivative.name, 
                          :width=>derivative.width, 
                          :height=>derivative.height, 
                          :status=>derivative.status, 
                          :url=>derivative.presigned_url(:get)}
        end
      end
      if item.status == Derivative::STATUS[:uploaded]
        items << {:id=>item.id, 
                  :status=>item.status, 
                  :created_at=>item.created_at, 
                  :valid_after=>item.valid_after, 
                  :url=>item.presigned_url(:get), 
                  :liked_by=>liked_by, 
                  :derivatives=>derivatives}
      end
    end

    @result[:user_id] = owner.id
    @result[:items] = items
    JSON.generate(@result)
  end

  get '/api/v1/viewer/users' do
    viewer = Viewer.find(:id=>params[:viewer_id])
    halt(400, "invalid viewer_id") if not viewer
    halt(400, "viewer_id unmatch") if @token.viewer_id != viewer.id

    users = []
    viewer.groups.each do |group|
      group.users.each do |user|
        users << {:user_id=>user.id}
      end  
    end
    @result[:users] = users
    JSON.generate(@result)
  end

  post '/api/v1/viewer/like' do
    item = Item.find(:id=>params[:item_id])
    halt(400, "invalid item_id") if not item

    viewer = Viewer.find(:id=>params[:viewer_id])
    halt(400, "invalid viewer_id") if not viewer

    halt(400, "viewer_id unmatch") if @token.viewer_id != viewer.id
    halt(400, "no access grant") if not check_item_access(item, viewer)

    r = ViewerLikeItem.find_or_create(:viewer_id=>viewer.id, :item_id=>item.id)
    r.count = 0 if not r.count
    r.count = r.count + 1
    r.updated_at = Time.now.to_i
    r.save

    @result[:item_id] = item.id
    @result[:viewer_id] = viewer.id
    @result[:count] = r.count
    JSON.generate(@result)
  end

  get '/api/*' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
    "get api request"
  end
end
