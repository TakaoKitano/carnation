$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

$valid_users = {}
$valid_items = {}
$invalid_users = {}
$invalid_items = {}

def is_valid_user?(id)
  return true if $valid_users[id]
  return false if $invalid_users[id]
  user = User.find(:id=>id)
  if user
    $valid_users[id] = true
    return true
  else
    $invalid_users[id] = true
    return false
  end
end

def is_valid_item?(id)
  return true if $valid_items[id]
  return false if $invalid_items[id]
  item = Item.find(:id=>id)
  if item
    $valid_items[id] = true
    return true
  else
    $invalid_items[id] = true
    return false
  end
end

def check_db(user_id, item_id)
  return is_valid_user?(user_id) && is_valid_item?(item_id)
end

def adhoc
    bucket = CarnationConfig.s3bucket
    deleted_total = 0
    total = 0
    bucket.objects.each do |obj|
      p "key=#{obj.key}"
      fDB = true
      m = /(?<user_id>\d{8})\/(?<item_id>\d{8})(?<ext>.jpg|.png|.mov|.mp4|.JPG|.PNG|.MOV|.MP4)/.match(obj.key)
      if m
        user_id = Integer(m[:user_id],10)
        item_id = Integer(m[:item_id],10)
        p "user_id==#{user_id}, item_id=#{item_id}"
        fDB = check_db(user_id, item_id)
      else
        m = /(?<user_id>\d{8})\/(?<item_id>\d{8})_\d\d(?<ext>.jpg|.png)/.match(obj.key)
        if m
          user_id = Integer(m[:user_id],10)
          item_id = Integer(m[:item_id],10)
          p "user_id==#{user_id}, item_id=#{item_id}"
          fDB = check_db(user_id, item_id)
        end
      end
      if fDB
          p "OK #{obj.key}"
          total = total + obj.content_length
      else
          p "NG #{obj.key} is not found in DB, deleting"
          deleted_total = deleted_total + obj.content_length
          obj.delete()
      end
    end
    p "total=#{total/(1024*1024*1024.0)} GB"
    p "deleted_total=#{deleted_total/(1024*1024*1024.0)} GB"
end

puts "cleanup s3"
adhoc()
