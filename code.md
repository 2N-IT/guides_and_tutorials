## Service Objects

Probably **Operation/Command/Action** or even **Process** would be a better name, but **Service Object** is most common name of this pattern/concept in Rails community, so lets stick to it.

### Why?

The Rails-way approach and the standard MVC pattern don't provide us with a meaningful place for complex business logic.

List below presents what can happen when you stick strictly to MVC:
- you could have **very large models** with logic seemingly related to it (e.g. creating an order object that also sends emails or updates stock levels, which also changes other models or performs "non-model" actions)
- you could have **very large controller methods**, which often results in code duplication if the same logic can be called in multiple places in the system and violates basic object-oriented programming principles such as SRP (the controller should accept parameters, call the appropriate class, and return its result to the view it renders, it should not be responsible for the details of a given action's logic).

As a result, it becomes **unreadable** and very difficult to test and maintain.

Therefore, one of the most frequently and quickly introduced concepts into MVC projects is the **ServiceObject**.

### What?

*“What is a Rails service object”* - definition / explanation written down by Andrzej Krzywda about 10 years ago, and still relevant:

>In my observation different programming communities have different meaning of service objects.
>
>
>Before I describe ‘the Rails meaning’ I’d like to quote some more generic definitions.
>
>- According to Martin Fowler’s - P of EEA Catalog:
>
> > Defines an application’s boundary with a layer of services that establishes a set of available operations and coordinates the application’s response in each operation.
>
>  - Bryan Helmkapp, the autor of famous “7 patterns to refactor Fat ActiveRecord models” described it as 
>    >Some actions in a system warrant a Service Object to encapsulate their operation.
>
>    I reach for Service Object when an action meets one or more of these criteria
>
>    - The action is complex (eg. closing the books at the end of accounting period )
>    - The action reaches accross multiple models (e.g. e-commerce purchase using Order, CreditCard and Customer objects)
>    - The action interacts with an external service (e.g. posting to social networks)
>    - The action is not a core concern of the underlying model ( e.g. sweeping up outdated data after a certain time period)
>    - There are multiple ways of performing the action (e.g. authenticating with an access token or password). This is the Gang of Four Strategy pattern.
>
>  - According to Eric Evans and his Domain-Driven Design: Tackling Complexity in the Heart of Software’s book:
>
> > Service: A standalone operation withing the context of your domain. A Service Object collects one or more services into an object. Typically you will have only one instance of each service object type within your execution context.
>  
>
>In the Rails world, the most popular defitnion seems to be: **everything that happens in the controller without all the HTTP-related stuff (params, render, redirect).**
>
>A service object encapsulates a single process of the business logic.


### How?

There are **hundreds** of different implementations of ServiceObjects (sometimes called *operations* or *processes*) to be found in the wild. All are based on the principles described above, but mainly differ in context of:
- error handling
- error storage
- result storage
- returned values and approach to accessing these data.

[In the approach we agreed upon as the default](https://github.com/mateuszbialowas/brug-service_objects/pull/4), we have established the following rules:

- SO is invoked once in the lifetime of the request in order to perform one task
- The data stored by SO (both errors and results) should not be changed in it
- SO returns itself
- In the returned object, we have access to the #errors method that stores information about errors (both unhappy-path and errors caught by rescue), and #result that stores information about the result or details of the error message if any occurred
- Additionally, the SO object has a #success? method that returns true if there is no indication in the @errors array (returned by the #errors method) that something went wrong with the happy-path
- In case of any [StandardError](https://www.honeybadger.io/blog/ruby-exception-vs-standarderror-whats-the-difference/), the BaseService catches such error, saves it in the errors array, and then interrupts further SO operations

[Examples of other approaches to SO](https://github.com/mateuszbialowas/brug-service_objects/pulls)

## Form Objects

Design pattern with a very descriptive name. It is an object used for forms. It is a very common pattern in Rails applications. It is used to encapsulate the logic of creating and updating models whenever it goes outside the ramifications of a regular CRUD operation. 

Most also use it to validate data from forms, either inside the form object directly, or by calling the model's validation methods or external validators.

### Why?

The main reason for using Form Objects is to:
- keep the controller clean
- keep the model clean
- keep the view clean
- help with testing the object create/update logic
- encapsulate the create/update logic for the object
- encapsulate the validation logic for the object
- encapsulate any logic that could be form specific
  - for example when form is split into steps in the view, and there is only one INSERT to the database at the very last step. FormObject can be used to store this data instead of model since it can be tailored just for this particular form. You just pass the params through request and initialize the form object with them
- reuse the same logic for create/update of a model across multiple places
- handle errors (not as frequently used, frowned upon by some)


It is mostly used when the logic of creating and updating models goes outside the ramifications of a regular CRUD operation.

### What?

Form Object is a class that can either wrap the model it eventually forms, or mirror its attributes with addition of its own attributes made especially for the form logic.

You won't meet this design pattern outside web development a lot since it is by definition used to `manage and encapsulate the handling of form data.`

Form objects, just like service objects, are also often used to mitigate problems with model callbacks that interact with external classes.

Form objects can also be used as replacement for `ActionController::StrongParameters` strategy, as all writable attributes are re-defined within each form. 

In some cases FormObject can be used as scaffolding for [replace method with object refactoring](https://sourcemaking.com/refactoring/replace-method-with-method-object).

As a last thing, they can be used as wrappers for virtual (with no model representation) or composite (saving multiple models at once) resources. In the latter case this may act as replacement for `ActiveRecord::NestedAttributes` which are commonly hated.

### How?

There are three main approaches to building Form Objects:
- Using rails module `ActiveModel::Model` - most popular, but Rails dependent
- Using 'virtus/dry-rb' gem - less popular, also Rails independent, but more plug-and-play and convention heavy than the PORO. Virtus is a deprecated gem now, dry-rb are its successors. You can still see a lot of older projects using the first one though.
- Using a PORO (plain old ruby object) - less (least?) popular, but most flexible and Rails independent (unless it gets coupled to model)

I will describe all three approaches below.

#### ActiveModel::Model

Those implementation can be as minimal as this:

```ruby
class BaseFormObject
  include ActiveModel::Model
end

class Users::RegistrationFormObject < BaseFormObject
  attr_accessor :email, :password, :password_confirmation
  validates :email, with: EMAIL_REGEXP
  validates :password, presence: true
end
```
This is enough for many, especially with simple forms, but then again, simple forms don't need Form Objects in the first place.

Let's look at a more detailed form object that has a more extensive public interface:

```ruby
    class BookRoomForm
      include ActiveModel::Model
    
      attr_accessor :user, :room, :date_from, :date_to
    
      validates_with BookHotelFormValidator
    
      def initialize(user:, room:, date_from: , date_to:)
        @user = user 
        @room = room 
        @date_from = date_from 
        @date_to = date_to 
      end

      def save
         return false unless valid?

         ActiveRecord::Base.transaction do
          room.bookings.create(booking_params)
         end
         raise ActiveRecord::Rollback unless errors.empty?
      end

      private
      
      def booking_params
        {
          user: user,
          date_from: date_from,
          date_to: date_to
        }
      end
      
      #... rest of the logic that could be connected
    end
```

In here, the form encapsulates the logic of a form that is used to book a room. It creates a booking for a room based on user and a date.

It uses an external validator, that it has access to thanks to `ActiveModel::Model` module.

It follows ActiveModel naming conventions

It has a very narrow interface with very few public methods. Usually, one or two at most (initialize and action with save to database)

It has access to errors just like the insides of a model thanks to the module.

It wraps the main action in transaction.

It has a private method that returns params for the booking and any other logic connected to handling the form for the user would be here.

It does not use a base form object. It depends on the module directly. Any other form object in the project would be expected to follow the same rules.

```ruby
# in some controller... maybe the room can be booked from room page and user page and main hotel page. you can use the same form for all of them adapting its code to fit the forms needs, since it is a general BookRoomForm (could alsob be called BookingForm)
room = Room.find(params[:room_id])

form = BookRoomForm.new(user: current_user, room: room, date_from: params[:date_from], date_to: params[:date_to])
form.save if form.valid? # once again, access to this method, granted by the module. It behaves like a model, but does not clutter the model with form specific code
form.errors.full_messages # and you can still access errors like you do with models
```

**This approach is the most popular among 2N developers**. It is also the most popular in the Rails community. The second one is rather obvious since it uses the Rails included module and blends in with models nicely.

It is rather **easy to test**, since you can use rspec-rails interface for models testing.

**It is also worth nothing, that other approaches might not be compatible with `form_for` in the view if you use that.**

#### Virtus/dry-rb

Approach I saw some companies/projects take. Virtus example should now be considered legacy, but since it can be still encountered, I present a simplistic and a more complex example that uses Virtus:

```ruby
class BaseFormObject
  include Virtus.model
  include ActiveModel::Validations
end

class UserFormObject < BaseFormObject
  attribute :name, String
  validates :name, presence: true
end

form = UserFormObject.new(name: 'Krzysio')
form.validate! # true
form.attributes # {:name=>"Krzysio"}
```

Now this mixes in virtus model interface, and only takes validations from ActiveModel. So you still handle validations as you would in the example I gave for rails module, but your attributes are handled according to Virtus API.

Now it is hard to see benefits of this approach over the first one, since you now mix two different interfaces over 1, rails standard one. One could point out a more approachable interface for virtual attributes using Virtus, and handling of non-persistent objects, but it has a cost of consitency.

So lets develop this into a more complex example:

```ruby
require "virtus"
require "action_controller/metal/strong_parameters"

class BaseFormObject
  include Virtus.model
  include ActiveModel::Validations

  Error = Class.new(StandardError)
  Invalid = Class.new(Error)
  NoParamKey = Class.new(Error)

  def initialize(*args)
    attributes = args.extract_options!

    attributes = args.pop.to_unsafe_h if attributes.blank? && args.last.is_a?(ActionController::Parameters)

    @resource = args.first

    super(build_original_attributes.merge(attributes))
  end

  def save
    valid? ? persist : false
  end

  def save!
    save.tap do |saved|
      raise Invalid unless saved
    end
  end

  def as(form_owner)
    @form_owner = form_owner
    self
  end

  def to_key
    nil
  end

  def to_partial_path
    nil
  end

  def to_model
    self
  end

  def to_param
    if resource.present? && resource.respond_to?(:to_param)
      resource.to_param
    else
      nil
    end
  end

  def persisted?
    if resource.present? && resource.respond_to?(:persisted?)
      resource.persisted?
    else
      false
    end
  end

  def model_name
    @model_name ||= OpenStruct.new(model_name_attributes)
  end

  def self.param_key(key = nil)
    if key.nil?
      @param_key
    else
      @param_key = key
    end
  end

  private

  attr_reader :resource, :form_owner

  def model_name_attributes
    if self.class.param_key.present?
      {
        param_key: self.class.param_key,
        route_key: self.class.param_key.pluralize,
        singular_route_key: self.class.param_key
      }
    elsif resource.present? && resource.respond_to?(:model_name)
      {
        param_key: resource.model_name.param_key,
        route_key: resource.model_name.route_key,
        singular_route_key: resource.model_name.singular_route_key
      }
    else
      raise NoParamKey
    end
  end
  
  def build_original_attributes
    return {} if resource.nil?
    base_attributes = resource.respond_to?(:attributes) && resource.attributes.symbolize_keys

    self.class.attribute_set.each_with_object(base_attributes || {}) do |attribute, result|
      if result[attribute.name].blank? && resource.respond_to?(attribute.name)
        result[attribute.name] = resource.public_send(attribute.name)
      end
    end
  end

  def persist
    raise NotImplementedError, "#persist has to be implemented"
  end
end
```
And lets use it:
```ruby
class UserForm < BaseFormObject
  param_key "person"

  attribute :first_name, String
  attribute :last_name, String
  attribute :age, Integer
  attribute :full_address, String
  attribute :skip_notification, Boolean

  validate :first_name, :last_name, presence: true

  private

  def persist
    update_user and
      update_address and
      deliver_notification
  end

  def update_user
    resource.update_attributes(attributes.except(:full_address, :skip_notification))
  end

  def update_address
    resource.address.update_attributes(full_address: full_address)
  end

  def deliver_notification
    skip_notification || UserNotifier.user_update_notification(user, form_owner).deliver
  end
end

class ReportConfigurationForm < BaseFormObject
  param_key "report"

  attribute :include_extra_data, Boolean
  attribute :dump_as_csv, Boolean
  attribute :comma_separated_column_names, String
  attribute :date_start, Date
  attribute :date_end, Date

  private

  def persist
    SendReport.call(attributes)
  end
end


#Console:
form = UserForm.new(User.find(1), params[:person])
form.save

form = UserForm.new(User.new, params[:person]).as(current_user)
form.save!

ReportConfigurationForm.new
ReportConfigurationForm.new({ include_extra_data: true, dump_as_csv: true })
```

What characterizes this appraoch:
   - `ActiveModel::Validations` still handles validation
   - `Virtus.model` handles attribute static method with all corresponding capabilities
   - Initialization support either a model or a simpler data structure (hash in example)
     - So the form works on (an optional) resource object as first constructor argument
     - It also accepts optional attributes hash as latter constructor argument
   - Each form needs to implement **#persist** method that returns falsey (if failed) or truthy (if succeeded) value.
   - **#resource** provides access to first constructor argument using
   - **#save** or **#save!** still handle validation and persistence
   - resource**#attributes** and public getters for resource are used to pre-populate attributes
   - Fields are populated with passed-in attributes hash and reverse-merged with pre-populated attributes if possible.
   - **#as** builder method populates internal _@form_owner_ variable (can be used to store current user).
   - **#param_key** method result can be defined/overridden their result by using _**.param_key**_ static method.
     - This defaults to **#resource#model_name#param_key**.
   - **#persisted?** method delegates to **#resource** if possible.
   - `ActionController::Parameters` are handled as attributes hash (using **to_unsafe_h**)
   - Can handle multiple models (transaction in **#persist** method is recommended in those cases)
     
This is in general more suited for replacing strong parameters or handling virtual and composite resources than rails module coupled approach. Rails models are not exactly build with those in mind, so this approach is more flexible since it still handles being used as rails model well (but not as natural, as rails module only approach).

The biggest drawback for this appraoch for me, is testing. Form objects built using this approach are **hard to test**.

#### dry-rb

This example would be pretty much as the above, but using different gems (Dry::Struct, Dry::Validation, Dry::Types)
Mostly it is used only for validation:

```ruby
  class UserFormObject < Dry::Validation::Contract

  params do
    required(:name).filled(:string)
  end

  rule(:name) do
    key.failure('must be present') if value.blank?
  end

end


form = UserFormObject.new
form.call(name: 'Sarin') # validate!
form.call(name: 'Sarin').values.data # return attributes '{:name=>"Sarin"}'
```
However, if you only use it for that, you might as well, simply do not validate in FormObject directly, but extract it to a separate validator class that you use in form object.

Benefits would be rails-independent validation, but you would still need to use rails module for attributes handling or build your own.

Also the dry-rb gems are easily extendable, and are multipurpose.
```ruby
class UserForm < Dry::Struct
  module Types
    include Dry::Types(default: :nominal)
  end
  attribute :id, Types::Integer.optional
  attribute :name, Types::String
  attribute :zone, Types::Integer
  
  attr_reader :user, :errors
  
  def save
    attributes = to_hash
    schema = UserContract.new.call(attributes)
    @errors = schema.errors(locale: I18n.locale).to_h.values.flatten
    return false unless errors.empty?
    
    @user = attributes[:id] ? User.find_by(id: attributes[:id]) : User.new
    @user.attributes = attributes.except(:id)
    @user.save
  end
end

class UserContract < Dry::Validation::Contract
  config.messages.namespace = :user
  config.messages.backend = :i18n # this allows for custom I18n paths
  schema do
    optional(:id)
    required(:name).filled(:string)
    required(:zone).filled(:string)
  end
  rule(:id, :name, :zone) do
    users = values[:id].nil? ? User.all : User.where.not(id: values[:id])
    key.failure(I18n.t('dry_validation.errors.user.exists')) if users.where(name: values[:name], zone: values[:zone]).exists?
  end
end
```

If you are working on a non-rails connected piece of code, you might want to consider the approach using the above gems.

If you utilize dry-rb in other parts of your code, this approach will also make your code more consistent.

#### PORO

Finally we have the most simplistic and diverse approach. This would differ based on project and developer, since it is considered that when you do a PORO form object, you cater it directly for the needs of the project. This could mean specific business or technology requirements. Maybe you do not have rails in a microservice. Maybe you want to decouple the code from rails as much as possible. Maybe including the rails module is too much for the needs of your form objects?

Whatever the need is, it is impossible to give one example that handles all cases. It does not exist. Instead I want to give some examples and explain why they could be used. This hopefully gives some direction about when to consider building a PORO form object.

This approach will work best with very complex forms, when you need to provide a lot of "bridge" code between the form layer and rails/backend layer.

It will also work well with very simple forms, but ones that are for example, multi stage. This is due to a lot of customization that would be required for those. You could avoid cluttering the object with rails-included stuff coming in from the model, that would be mostly unneeded in those cases.

```ruby
class BaseFormObject
  attr_reader :object
  def initialize(object)
    attrs_const_name = "#{object.class.name}FormObject::ATTRS"
    raise NotImplementedError, "You must define ATTRS constant in #{self.class.name}" unless attrs_const_name.constantize

    @object = object
    object.attributes.each do |key, value|
      send("#{key}=", value) if key.to_sym.in?(attrs_const_name.constantize)
    end
  rescue NameError => e
    raise NotImplementedError if e.message.include?("uninitialized constant #{attrs_const_name}")
    raise e
  end

  def attributes
    self.class::ATTRS.each_with_object({}) do |attr, hash|
      hash[attr] = send(attr)
    end
  end

  def self.validates_with(contract)
    define_method(:valid?) { contract.new.call(attributes).success? }
    define_method(:invalid?) { !valid? }
    define_method(:errors) { contract.new.call(attributes).errors.to_h }
  end
end
```

a simple spec:

```ruby

RSpec.describe BaseFormObject do
  context "when no ATTRS defined" do
    class UserFormObject < BaseFormObject; end # standard:disable Lint/ConstantDefinitionInBlock

    it "raises NotImplementedError" do
      expect { UserFormObject.new(User.new) }.to raise_error(NotImplementedError)
    end
  end
end
```

And an object using this:

```ruby
class OrderFormObject < BaseFormObject
  validates_with OrderFormContract
  ATTRS = [:id, :name, :comments, :quantity, :provider_id].freeze
  attr_accessor(*ATTRS)

  delegate :order, :product_id, to: :object

  def initialize(object)
    super
    @storage = Warehouse.find_by(location: object.current_location)
  end

  def save(new_location, product_name)
    object.name = product_name
    object.new_location = new_location
    if valid?
      object.save
      @storage.nil? ? provider.track_storage : @storage.update_stock
    end
  end
  
  private

  def provider
    @provider ||= Provider.find_by(id: provider_id)
  end

  def collections
    return object.collections if object.provider == provider
    []
  end

  def collections_data
    #... more logic connected to the view
  end
end
```

As you can see this particular form object does not have too much rails connected logic. BaseFormObject also extract validations to external validtor, to which every FormObject is connected.
BaseFormObject works on assumptions:
  - Form will work on model instance
  - Forms will follow a naming convention
  - Forms will have a constant with attributes that will be used, making for a more explicit interface
  - Validations are handled outside of the form object but it is connected to the validator object

This FormObject is suited to work on a very particular, multi-stage form, that does not use a lot of rails code, and needs to cater to business logic a lot, pass data to html outside of the form itself for JS purposes etc.
It is more extendable but remains simple (in the BaseFormObject), giving only a general directions about implementation of every form object.

Those kind of form objects are the **easiest to test**, since they are the most independent ones, and it is best to be created with TDD.
