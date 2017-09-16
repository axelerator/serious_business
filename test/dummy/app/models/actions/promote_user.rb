class PromoteUser < SeriousBusiness::Action
  needs :user

  forbid_if :not_privileged { |action| !action.actor.privileged? }

  def execute
    user.update_attributes!(role: :privileged)
    [user]
  end
end

