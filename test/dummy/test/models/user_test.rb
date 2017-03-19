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
    action = user.create_user(params: {name: 'MyNewUser'})

    assert_difference 'User.count' do
      action.execute!
    end

    new_user = User.order(:created_at).last
    assert_equal 'MyNewUser', new_user.name
  end

  test 'created user knows who created it' do
    creator = users(:admin_axel)
    creator.create_user(params: {name: 'MyNewUser'}).execute!
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
    action = actor.update_user(for_model: user, params: {name: new_name})
    assert action.execute!

    reloaded_user = User.find(user.id)
    assert_equal new_name, reloaded_user.name
  end

  test 'PromoteUser actually promotes a user' do
    actor = users(:admin_axel)
    user = users(:user_ursel)

    action = actor.promote_user(for_model: user)
    assert action.execute!

    reloaded_user = User.find(user.id)
    assert reloaded_user.privileged?
  end

  test "Unprivileged user cannot promote other users" do
    promoter = users(:user_ulrich)
    promoted = users(:user_ursel)

    action = promoter.promote_user(for_model: promoted)

    refute action.can?
    action.execute!

    reloaded_promoted = User.find(promoted.id)
    assert reloaded_promoted.unprivileged?
  end

  test "presence validation on form model" do
    actor = users(:admin_axel)
    user = users(:user_ursel)

    action = actor.update_user(for_model: user, params: {name: nil})
    refute action.execute!

    assert action.form_model.errors.any?
    assert action.form_model.errors[:name].any?
    assert_equal 'can\'t be blank', action.form_model.errors[:name].first
  end

  test "length validation on form model" do
    actor = users(:admin_axel)
    user = users(:user_ursel)

    action = actor.update_user(for_model: user, params: {name: 'ab'})
    refute action.execute!

    assert action.form_model.errors.any?
    assert action.form_model.errors[:name].any?
    assert_equal 'is too short (minimum is 3 characters)', action.form_model.errors[:name].first
  end

end
