require "serious_business/engine"

module SeriousBusiness

  SeriousBusinessConfig = Struct.new(:actor_class_name)

  def self.config &blk
    @config ||= SeriousBusinessConfig.new
    blk.call(@config)
  end

  def self.actor_class
    @config.actor_class_name
  end
end
