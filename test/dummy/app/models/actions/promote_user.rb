class PromoteUser < SeriousBusiness::Action
  needs :user

  def execute
    user.update_attributes!(role: :privileged)
    [user]
  end
end

