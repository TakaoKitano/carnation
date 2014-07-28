require 'models'
require 'resque'
require 'resque-retry'
require 'resque-timeout'

class CreateDerivatives
  extend Resque::Plugins::Retry
  @queue = :default
  @retry_limit = 2
  def self.perform(param)
    item_id = param["item_id"]
    p "item_id=#{item_id}"
    Item.create_derivatives(item_id)
  end
end
