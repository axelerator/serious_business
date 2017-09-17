require "serious_business/engine"
require "generators/serious_business/install_generator"
#require "i18n-dot_lookup"

module SeriousBusiness

  SeriousBusinessConfig = Struct.new(:actor_class_name)

  def self.config &blk
    @config ||= SeriousBusinessConfig.new
    blk.call(@config)
  end

  def self.actor_class_name
    @config.actor_class_name
  end

end
