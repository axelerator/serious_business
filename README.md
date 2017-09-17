# SeriousBusiness: Best application pratices in a handsome DSL

A small library helping app developers to comply with basic usability and security pattern.
By encapsulating business actions in separate classes good pratices are enforced and controllers and models are less likely to turn into [God objects](https://en.wikipedia.org/wiki/God_object)

Using it you will get:

  * a declarative DSL to specify authorization
  * a simple way to check permissions object based in views
  * a guided mechanism to a concise user experience
  * a simpler way to test logic that before went into controllers
  * transactional business actions per default
  * automagic tracking on which users and actions affecting you models


## Installation
Add this line to your application's Gemfile:

```ruby
gem 'serious_business'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install serious_business
```
## Usage

The gem uses polymorphic associations to track the actions you specify. For that it creates some tables and a initializer you may need to modify:

    rails g serious_business:install

The gem expects one model class to act as *actor* for your actions. The default for this is `User`.

You will need to make the following changes to you model class to be aware of the actions:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include SeriousBusiness::Actor
end

# this is needed for hot code replacement in dev mode to work
# assuming you put your actions in app/models/actions
Dir[Rails.root.join('app','models', 'actions', '*.rb')].each {|file| require_dependency file }
```

To create a 'business action' you inherit from `SeriousBusiness::Action`
```ruby
# app/models/actions/update_user.rb
module Actions
  class UpdateUser < SeriousBusiness::Action
    # this action needs to be initialized with a user that should be updated
    needs :user

    # this actions reads the email from a hash most likely set from params
    att :email, presence: true


    # this action should be able to change only the user
    # that is executing the action
    forbid_if :not_self { |action| action.actor != action.user }

    # unless it's an admin - they are allowed to do everything, right?
    allow_if {|action| action.actor.admin? }


    # implement this method to specify the actual logic of the action.
    # return an array of all objects that are logically affected by the 
    # change (the actor is persisted automatically)
    def execute
      user.update_attributes(email: form_model.email)
      [user]
    end
  end
end

```

By creating action classes you actor class (the class you included `SeriousBusiness::Actor` in) gets a method for every action.
For the above example that means you can now call:

    action = user.update_user

Since we declared that this action applies to another user we can pass other user like this:

```ruby
other_user = User.find(params[:user_id])
action = user.update_user.for_user(other_user)
```

Since we now specified everything thats 'needed' for the action, we can ask if the action can be executed. And since we created it from an user as actor it can anwser itself:


```ruby
action.can? # will return if user.admin? or user == other_user
```
And since it's an action that takes further data probably generated from a form submit we have to pass that in to actually execute the action


```ruby
action = user.update_user.for_user(other_user).with_params(email: 'foo@example.org')

# Note the exclamation mark at the end of 'execute!'
action.execute! # true if the action was executed successfully
                # this is transactional - no changes are made to the db
                # if anything prevents the action from succeeding (ie.
                # failing guards/permissions or validations)
```
Actions themselves are fully fleged ActiveRecord Models that are persisted when successfully executed. With them references to the affected models you return from you implementation of the `execute` are stored.

To access the list of actions that affected an object you have to include the include `SeriousBusiness::AffectedByActions` concern. Since in this model we modify the User:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include SeriousBusiness::Actor
  include SeriousBusiness::AffectedByActions
end
``` 

Afterwards you can retrieve all actions that affected this model.

```ruby
  actions = user.modifiers # [SeriousBusiness::Action]
  actions.last.actor       # The User that executed the action
  actions.last.description # A textual description of the action
``` 

SeriousBusiness encurages to maintain human consumable descriptions for a better
user experience

To start create the following structure in your i18n yaml file:

```
  serious_action:
    description_with_failed_guards: '%{description} not possible because %{reasons}'
    failed_guard_join_with: ' and '
    update_user
      description: Updating user data
      cta: update
      guards:
        not_self: you are not this user 
```

This enables you to generate descriptive labels for those actions independent of their location of use:

```
    action = user.update_user.for_user(other_user)
    action.cta_label # 'update' - ie for buttons

    action.description # 'Updating the user' - i.e. for history

    # the description is extended automatically if the action can not be executed
    action.description # 'Updating the user not possible because you are not this user'
```

The latter is especially useful to give the user meaningful feedback to an unavailble action:

```
  <% if update_action.can? %>
    <%= link_to 'Edit', edit_account_path(account) %>
  <% else %>
    <span title= "<%= update_action.description %>" >Edit</span>
  <% end %>
```


## Contributing

Pull-requests are welcome - with tests loved!

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
