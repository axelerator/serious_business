# stores the relation between a model and an action affecting it
class SeriousBusiness::Affected < ApplicationRecord
  self.table_name = 'serious_affecteds'
  belongs_to :action, class_name: 'SeriousBusiness::Action', foreign_key: 'serious_action_id'
  belongs_to :affected, polymorphic: true
end


