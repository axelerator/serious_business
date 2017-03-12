module SeriousBusiness
  class Action < ApplicationRecord
    self.table_name= 'serious_actions'
    belongs_to :actor, class_name: SeriousBusiness.actor_class_name
    has_many :affecteds
    has_many :affectables, through: :affecteds

    def self.att(name, options = {})
      name = name.to_sym
      self.form_model_class.send(:attr_accessor, name)
      if !!options[:presence]
        self.form_model_class.validates name, presence: true
      end
      self.custom_attributes << name
    end

    def self.required_attributes
      @_required_attributes ||= []
    end

    def self.needs(name)
      required_attributes << name.to_sym
      self.send(:attr_reader, name)
    end

    def self.form_model_class
      @model_class ||= begin
                        clazz = Class.new do
                          def persisted?
                            # is set on instantiation
                            @_action.persisted?
                          end

                          def to_key
                            nil
                          end

                          def to_param
                            @_action.class.param_name
                          end

                          def attributes
                            @_action.class.custom_attributes.inject({}) do |sum, attr_name|
                              sum[attr_name] = self.instance_variable_get("@#{attr_name}")
                              sum
                            end
                          end
                        end
                        self.const_set(:FormModel, clazz)
                        clazz.include ActiveModel::AttributeAssignment
                        clazz.include ActiveModel::Validations
                        clazz
                       end
    end

    def self.custom_attributes
      @_attribs ||= []
    end

    def self.param_name
      name.demodulize.underscore
    end


    def self.build(actor_id: , for_model: [], params: {} )
      action = self.new(actor_id: actor_id)
      if params.respond_to? :require
        params = params
                  .require(param_name)
                  .permit self.custom_attributes
      end
      for_model = Array.wrap(for_model)
      self.required_attributes.each_with_index do |needed_name, idx|
        action.instance_variable_set "@#{needed_name}", for_model[idx]
      end
      action.init_from_needed
      action.form_model.assign_attributes(params) unless params.empty?
      action
    end

    def init_from_needed
    end

    def form_model(params={})
      @_form_model ||= begin
        model_instance = self.class.form_model_class.new
        model_instance.instance_variable_set(:@_action, self)
        model_instance.assign_attributes(params || {})
        model_instance
                       end
    end

    def params
      form_model
    end

    def actor_class
      @_actor_class ||= begin
                          raise "No actor_class specified! #TODO link to config" unless SeriousBusinessConfig.actor_class_name.present?
                          Kernel.const_get(SeriousBusinessConfig.actor_class_name)
                        end
    end

    def self.inherited(child_class)
      super
      method_name = child_class.name.demodulize.underscore
      actor_class = Kernel.const_get SeriousBusiness.actor_class_name

      if actor_class.respond_to? method_name
        raise "Action with the same name already registered #{child_class.name}"
      end

      Rails.logger.debug "Registering action #{method_name}"

      actor_class.send(:define_method, method_name) do |params: {}, for_model: nil|
        child_class.build(actor_id: self.id, for_model: for_model, params: params)
      end
    end

    def execute!
      result = nil
      self.class.transaction do
        begin
          if self.class.custom_attributes.any? && !form_model.valid?
            return nil
          end
          affected_models = self.execute
          self.save!
          affected_models.each do |model|
            Affected.create!(action: self, affected: model)
          end
          result = @subject || true
        rescue Exception => e
          raise e
        end
      end
      result
    end

    protected

    # use this from your execute method to set the object returned
    # by the action when actalley being executed
    def subject=(subject)
      @subject = subject
    end

    def execute
      raise "execute should be overwritten in subclass"
    end
  end


end

