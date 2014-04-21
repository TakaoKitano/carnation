$LOAD_PATH.push('.') if not $LOAD_PATH.include?('.')
$LOAD_PATH.push('./lib') if not $LOAD_PATH.include?('./lib')

require 'models'

class CreateDerivatives
  @queue = :default
  def self.perform(param)
    p "!!!!!CreateDerivatives perform called!!!!"
    item_id = param["item_id"]
    p "item_id=#{item_id}"
    Item.create_and_upload_derivatives(item_id)
  end
end

