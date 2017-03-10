require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'test' do
    assert_kind_of User, users(:admin_axel)
  end

  test 'initializer worked' do
    SeriousBusiness.actor_class_name == :User
  end

  test 'user gets a method for each action' do
    user = users(:admin_axel)
    action = user.create_user

    assert_kind_of SeriousBusiness::Action, action
  end


end
