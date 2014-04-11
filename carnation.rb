require 'date'
require 'aws-sdk'
require './models'

class Carnation
  def initialize
    @s3 = AWS::S3.new
    @bucket = @s3.buckets['carnationdata']
  end

  def initiate_upload(params)
    user_id = params["user_id"].to_i
    item_id = params["item_id"].to_i
    extension = params["extension"] 

    user = User.where(:id=>user_id).first 
    return {:error=>"user_id invalid"} if not user 

    if (item_id > 0) 
      item = Item.where(:id=>item_id).first 
      return {:error=>"item_id invalid"} if not item 
    else 
      return {:error=>"no extension"} if not extension 
      return {:error=>"extension invalid"} if extension.index('.') != 0
      item = Item.new(user, extension)
        item.status = $DB_ITEM_STATUS[:initiated]
        item.name = params["name"]
        item.width = params["width"].to_i
        item.height = params["height"].to_i 
        item.duration = params["duration"].to_i
        item.filesize = params["filesize"].to_i
      item.save
    end

    s3obj = @bucket.objects[item.path + extension]
    ps = AWS::S3::PresignV4.new(s3obj)
    uri = ps.presign(:put, :expires=>Time.now.to_i+28800,:secure=>true, :signature_version=>:v4)
    return {:item_id=>item.id, :url=>uri.to_s}
  end

  def notify_uploaded(params)
    item_id = params["item_id"].to_i
    user_id = params["user_id"].to_i
    p "item_id=" + item_id.to_s + " user_id=" + user_id.to_s
    item = Item.where(:id=>item_id).first 
    return {:error=>"item_id invalid"} if not item 
    return {:error=>"user_id invalid"} if item.user_id != user_id
    valid_after = params["valid_after"].to_i
    valid_after = 300 if valid_after <= 0

    item.valid_after = Time.at(Time.now.to_i + valid_after).to_i
    item.status = $DB_ITEM_STATUS[:uploaded]
    item.save

    return {:item_id=>item.id}
  end

  def get_user_images(params)
    user_id = params["user_id"].to_i
    count = params["count"].to_i
    count = 20 if count <= 0

    greater_than = params["greater_than"].to_i
    less_than = params["less_than"].to_i
    offset = params["offset"].to_i

    ds = Item.where(:user_id => user_id)

    if greater_than > 0
      ds = ds.where('id > ?', greater_than)
    end
    if less_than > 0
      ds = ds.where('id < ?', less_than)
    end
    if offset > 0
      ds = ds.offset(offset)
    end

    ds = ds.limit(count).order_by(:id)
    items = ds.all
    images = []
    items.each do |item|
      liked_by = []
      item.viewers.each do |viewer|
        liked_by << viewer.id
      end
      derivatives = []
      item.derivatives.each do |derivative|
        derivatives << {:id=>derivative.id, :url=>presigned_url(derivative)}
      end
      images << {:id=>item.id, :status=>item.status, :valid_after=>item.valid_after, :url=>presigned_url(item), :liked_by=>liked_by, :derivatives=>derivatives}
    end
    return {:user_id=>user_id, :items=>images}
  end

  private
  def presigned_url(item)
    s3obj = @bucket.objects[item.path + item.extension]
    ps = AWS::S3::PresignV4.new(s3obj)
    uri = ps.presign(:get, :expires=>Time.now.to_i+28800,:secure=>true, :signature_version=>:v4)
    uri.to_s
  end

end
