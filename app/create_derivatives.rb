require 'models'

class CreateDerivatives
  extend Resque::Plugins::Retry
  @queue = :default
  @retry_limit = 1
  def self.perform(param)
    item_id = param["item_id"]
    CarnationConfig.logger.info "CreateDerivatives item_id=#{item_id}"
    result = Item.create_derivatives(item_id)
  rescue
    CarnationConfig.logger.info "exception while performing create_derivatives item_id=#{item_id}"
    result = false
  ensure
    raise "CreateDerivatives Error" unless result
  end
end
