require 'models'

class CreateDerivatives
  @queue = :default
  def self.perform(param)
    item_id = param["item_id"]
    p "item_id=#{item_id}"
    Item.create_and_upload_derivatives(item_id)
  end
end
