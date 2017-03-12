module SeriousBusiness::AffectedByActions
  extend ActiveSupport::Concern

  included do |clazz|
    clazz.has_many :serious_affecteds, as: :affected, class_name: 'SeriousBusiness::Affected'
    clazz.has_many :modifiers, through: :serious_affecteds, source: :action

  end
end
