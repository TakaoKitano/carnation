class CreateDerivatives
  @queue = :default
  def self.perform(content)
    p "!!!!!CreateDerivatives perform called!!!!"
    p content
  end
end

