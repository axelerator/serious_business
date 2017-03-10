class User < ApplicationRecord
  enum role: [:privileged, :unprivileged]

end
