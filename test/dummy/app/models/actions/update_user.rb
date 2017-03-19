class UpdateUser < SeriousBusiness::Action
  needs :user
  att :name, presence: true

  def init_from_needed
    form_model.take_attributes_from(user)
  end


  def execute
    user.update_attributes!(form_model.attributes)
    [user]
  end
end
