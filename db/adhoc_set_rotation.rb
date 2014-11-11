$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

def adhoc
    Item.where.update(:rotation => 0)
    
    Item.where(:extension=>".mov").where(:status=>1).all.each do |item|
      p "#{item.id}: activating"
      Item.create_derivatives(item.id)
    end
end

puts "set timezones"
adhoc
