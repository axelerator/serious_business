class UpdateUser < SeriousBusiness::Action
  needs :user
  att :name, presence: true

  def init_from_needed
    form_model.assign_attributes(user.attributes.slice(*self.class.custom_attributes.map(&:to_s)).symbolize_keys)
  end


  def execute
    user.update_attributes!(form_model.attributes)
    [user]
  end
end
