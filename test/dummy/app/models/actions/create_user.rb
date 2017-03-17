class CreateUser < SeriousBusiness::Action
  att :name, presence: true

  def execute
    user_params = form_model.attributes.merge(role: :unprivileged)
    new_user = User.create!(user_params)
    [new_user]
  end
end

