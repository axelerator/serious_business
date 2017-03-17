class PromoteUser < SeriousBusiness::Action
  needs :user

  allow_if -> { privileged? }

  def execute
    user.update_attributes!(role: :privileged)
    [user]
  end
end

