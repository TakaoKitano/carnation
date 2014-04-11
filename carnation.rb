require 'date'
require 'aws-sdk'
require './models'

class Carnation
  def initialize
    @s3 = AWS::S3.new
    @bucket = @s3.buckets['carnationdata']
  end

  def initiate_upload(params)
    user = User.where(:id=>params["user_id"].to_i).first 
    return {:error=>"user_id invalid"} if not user 
    extension = params["extension"] 
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
    valid_after = 1800 if valid_after <= 0

    item.valid_after = Time.at(Time.now.to_i + valid_after)
    item.save

    return {:item_id=>item.id}
  end

end
