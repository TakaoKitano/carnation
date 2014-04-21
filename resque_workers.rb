$LOAD_PATH.push('.') if not $LOAD_PATH.include?('.')
$LOAD_PATH.push('./lib') if not $LOAD_PATH.include?('./lib')

require 'models'

class CreateDerivatives
  @queue = :default
  def self.perform(content)
    p "!!!!!CreateDerivatives perform called!!!!"
    p content
  end
end

