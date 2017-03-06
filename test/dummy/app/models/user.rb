class User < ApplicationRecord
  enum role: [:privileged, :unprivileged]

  class CreateUser < SeriousBusiness::Action
    att :name, presence: true

    def execute
      new_user = User.create!(form_model.attributes)
      [new_user]
    end
  end
end
