$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

def adhoc
    Item.where.update(:timezone => CarnationConfig.default_timezone)
    User.where.update(:timezone => CarnationConfig.default_timezone)
    Viewer.where.update(:timezone => CarnationConfig.default_timezone)
    
    Item.all.each do |item|
      if not item.shot_at
        item.shot_at = item.created_at
        item.save 
      end
    end
end

puts "set timezones"
adhoc
