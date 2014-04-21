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
    p "access_token:", @token if @token
  end

  post '/api/v1/item/initiate' do

    user_id = params[:user_id].to_i
    item_id = params[:item_id].to_i
    extension = params[:extension] 

    user = User.where(:id=>user_id).first 
    halt(400, "user_id invalid") if not user

    if item_id > 0 
      item = Item.where(:id=>item_id).first 
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

    user = User.where(:id=>params[:user_id]).first 
    halt(400, "user_id invalid") if not user

    ds = Item.where(:user_id => user.id)
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
      item.viewers.each do |viewer|
        liked_by << viewer.id
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
                :valid_after=>item.valid_after, 
                :url=>item.presigned_url(:get), 
                :liked_by=>liked_by, 
                :created_at=>item.created_at, 
                :derivatives=>derivatives}
    end

    @result[:user_id] = user.id
    @result[:items] = items
    JSON.generate(@result)
  end

  get '/api/*' do
    token = request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    p "access_token:", token if token
    "get api request"
  end
end
