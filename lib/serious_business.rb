require "serious_business/engine"
require "generators/serious_business/install_generator"
module SeriousBusiness

  SeriousBusinessConfig = Struct.new(:actor_class_name)

  def self.config &blk
    @config ||= SeriousBusinessConfig.new
    blk.call(@config)
    reload_actions!
  end

  def self.actor_class_name
    @config.actor_class_name
  end

  def self.reload_actions!
    Dir[Rails.root.join('app','models', 'actions', '*.rb')].each {|file| require file }
  end

end
