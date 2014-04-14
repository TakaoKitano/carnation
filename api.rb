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

  post '/apiv1/initiate_item' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token

    user_id = params[:user_id].to_i
    item_id = params[:item_id].to_i
    extension = params[:extension] 

    user = User.where(:id=>user_id).first 
    halt(400, "user_id invalid") if not user

    if (item_id > 0) 
      item = Item.where(:id=>item_id).first 
      halt(400, "item_id invalid") if not item
    else 
      halt(400, "extension required") if not extension
      halt(400, "extension invalid") if extension.index('.') != 0
      item = Item.new(user, extension)
        item.status = $DB_ITEM_STATUS[:initiated]
        item.name = params[:name]
        item.width = params[:width].to_i
        item.height = params[:height].to_i 
        item.duration = params[:duration].to_i
        item.filesize = params[:filesize].to_i
      item.save
    end

    body = {}
    body[:item_id] = item.id
    body[:url] = item.presigned_url(:put)
    response['Content-Type'] = 'application/json'
    json = JSON.generate(body)
  end

  get '/carnation/api/notify_uploaded' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
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
    item.status = $DB_ITEM_STATUS[:uploaded]
    item.save

    body = {}
    body[:item_id] = item_id
    response['Content-Type'] = 'application/json'
    JSON.generate(body)
  end


  get '/carnation/api/get_user_images' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token

    user = User.where(:id=>params[:user_id]).first 
    halt(400, "user_id invalid") if not user


    ds = Item.where(:user_id => user.id)

    greater_than = params["greater_than"].to_i
    if greater_than > 0
      ds = ds.where('id > ?', greater_than)
    end
    less_than = params["less_than"].to_i
    if less_than > 0
      ds = ds.where('id < ?', less_than)
    end
    offset = params["offset"].to_i
    if offset > 0
      ds = ds.offset(offset)
    end

    count = params[:count].to_i
    count = 20 if count == 0
    ds = ds.limit(count)

    ds = ds.order_by(:created_at)
    items = []
    ds.all.each do |item|
      liked_by = []
      item.viewers.each do |viewer|
        liked_by << viewer.id
      end
      derivatives = []
      item.derivatives.each do |derivative|
        derivatives << {:id=>derivative.id, :url=>derivative.presigned_url(:get)}
      end
      items << {:id=>item.id, 
                :status=>item.status, 
                :valid_after=>item.valid_after, 
                :url=>item.presigned_url(:get), 
                :liked_by=>liked_by, 
                :created_at=>item.created_at, 
                :derivatives=>derivatives}
    end

    body = {}
    body[:user_id] = user.id
    body[:items] = items
    response['Content-Type'] = 'application/json'
    JSON.generate(body)
  end

  get '/api/*' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
    "get api request"
  end
end
