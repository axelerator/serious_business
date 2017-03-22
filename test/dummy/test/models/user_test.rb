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

  test 'create user action actually creates a user' do
    user = users(:admin_axel)
    action = user.create_user.with_params(name: 'MyNewUser')

    assert_difference 'User.count' do
      action.execute!
    end

    new_user = User.order(:created_at).last
    assert_equal 'MyNewUser', new_user.name
  end

  test 'created user knows who created it' do
    creator = users(:admin_axel)
    action = creator.create_user.with_params(name: 'MyNewUser')
    action.execute!
    new_user = User.order(:created_at).last

    assert_not_nil new_user.serious_affecteds.first

    create_action = new_user.modifiers.first
    assert_not_nil create_action
    assert_equal creator, create_action.actor
  end

  test 'update action affects database row' do
    actor = users(:admin_axel)
    user = users(:user_ursel)

    new_name = 'NewName'
    action = actor.update_user.for_user(user).with_params(name: new_name)
    assert action.execute!

    reloaded_user = User.find(user.id)
    assert_equal new_name, reloaded_user.name
  end

  test 'PromoteUser actually promotes a user' do
    actor = users(:admin_axel)
    user = users(:user_ursel)

    action = actor.promote_user.for_user user
    assert action.execute!

    reloaded_user = User.find(user.id)
    assert reloaded_user.privileged?
  end

  test "Unprivileged user cannot promote other users" do
    promoter = users(:user_ulrich)
    promoted = users(:user_ursel)

    action = promoter.promote_user.for_user promoted

    refute action.can?
    action.execute!

    reloaded_promoted = User.find(promoted.id)
    assert reloaded_promoted.unprivileged?
  end

  test "presence validation on form model" do
    actor = users(:admin_axel)
    user = users(:user_ursel)

    action = actor.update_user.for_user(user).with_params(name: nil)
    refute action.execute!

    assert action.form_model.errors.any?
    assert action.form_model.errors[:name].any?
    assert_equal 'can\'t be blank', action.form_model.errors[:name].first
  end

  test "length validation on form model" do
    actor = users(:admin_axel)
    user = users(:user_ursel)

    action = actor.update_user.for_user(user).with_params(name: 'ab')
    refute action.execute!

    assert action.form_model.errors.any?
    assert action.form_model.errors[:name].any?
    assert_equal 'is too short (minimum is 3 characters)', action.form_model.errors[:name].first
  end

  test "action with mandatory model cannot be used without" do
    actor = users(:admin_axel)
    assert_raises SeriousBusiness::Action::MissingModelException do
      actor.update_user.with_params(name: 'some name')
    end
  end

end
