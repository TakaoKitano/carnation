$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

def add_file_hash()
    Item.all.each do |item|
      if item.status == 1
        p "#{item.id} activated - re-activate "
        Item.create_derivatives(item.id)
      elsif item.status == 0
        p "#{item.id} not activated - deleting"
        item.destroy
      elsif item.status == 2
        p "#{item.id} is deleted - deleting"
        item.destroy
      end
    end
end

puts "add_file_hash"
add_file_hash()
