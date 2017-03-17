class User < ApplicationRecord
  include SeriousBusiness::AffectedByActions
  include SeriousBusiness::Actor
  enum role: [:privileged, :unprivileged]
end
