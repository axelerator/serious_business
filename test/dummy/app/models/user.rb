class User < ApplicationRecord
  include SeriousBusiness::AffectedByActions

  enum role: [:privileged, :unprivileged]
end
