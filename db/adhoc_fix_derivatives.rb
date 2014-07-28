$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../lib')
$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '../app')

require 'models'

def fix_derivatives
    Item.all.each do |item|
      if item.status == 1
        if item.derivatives.size != 2
          p "need creating derivatives for #{item.id}"
          Item.create_derivatives(item.id)
        else
          derivatives = item.derivatives
          if not derivatives[0].extension or
             not derivatives[0].path or
             not derivatives[1].extension or
             not derivatives[1].path
            p "found imcomplete derivatives for #{item.id}"
            Item.create_derivatives(item.id)
          end
        end
      end
    end
end

puts "fix derivatives"
fix_derivatives
