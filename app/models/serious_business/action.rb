module SeriousBusiness
  class Action < ApplicationRecord
    self.table_name= 'serious_actions'
    belongs_to :actor, class_name: SeriousBusiness.actor_class_name
    has_many :affecteds, foreign_key: :serious_action_id
    has_many :affectables, through: :affecteds, source: :affected
    attr_accessor :transient_affected_models

    def self.att(name, options = {})
      name = name.to_sym
      self.form_model_class.send(:attr_accessor, name)
      if options.any?
        self.form_model_class.validates name, options
      end
      self.needed_attributes << name
    end

    def self.required_attributes
      @_required_attributes ||= []
    end

    class MissingModelException < StandardError
      def initialize(model_names)
        method_names = model_names.map{|n| "for_#{n}"}.join(', ')
        super("You have to call the following methods before setting params #{method_names}")
      end
    end

    def with_params(params = {})
      if params.respond_to? :require
        params = params
                  .require(self.class.param_name)
                  .permit!
        params.to_h.slice!(*self.class.needed_attributes.map(&:to_s))
      end

      # make sure 'needed' models were set before trying to apply params
      missing_values = self.class.required_attributes.select do |needed_name|
        self.send(needed_name).nil?
      end
      raise MissingModelException.new(missing_values) if missing_values.any?

      reset_form_model
      form_model.assign_attributes(params) unless params.empty?
      self
    end

    def self.needs(name)
      required_attributes << name.to_sym
      self.send(:attr_reader, name)
      self.send(:define_method, "for_#{name}") do |needed|
        reset_form_model
        self.instance_variable_set("@#{name}", needed)
        self
      end
    end

    def self.guards
      @_guards ||= []
    end

    IfGuard = Struct.new(:prc) do
      def pass?(action)
        action.actor.instance_exec(action, &prc)
      end
    end

    UnlessGuard = Struct.new(:reason, :prc) do
      def pass?(action)
        !action.actor.instance_exec(action, &prc)
      end
    end

    def self.forbid_if reason, &blk
      guards << UnlessGuard.new(reason, blk)
    end

    def self.allow_if prc
      guards << IfGuard.new(prc)
    end

    def failed_guards
      if_guards, unless_guards = self.class.guards
                                    .partition{ |guard| guard.is_a?(IfGuard) }

      return [] if Array.wrap(if_guards).any?{|g| g.pass?(self)}

      Array.wrap(unless_guards).select do |guard|
        !guard.pass?(self)
      end
    end

    def full_guard_messages
      failed_guards
        .map(&:reason)
        .map do |reason|
          i18n = I18n.t("serious_action.#{self.class.param_name}.guards.#{reason}")
          if i18n.starts_with? 'translation missing:'
            global_i18n = I18n.t("serious_action.global_guards.#{reason}")
            i18n = global_i18n unless global_i18n.starts_with? 'translation missing:'
          end
          i18n
        end.join(I18n.t('serious_action.failed_guard_join_with'))
    end

    def can?
      failed_guards.empty?
    end

    def self.form_model_class
      @model_class ||= begin
                        clazz = Class.new(BaseFormModel)
                        self.const_set(:FormModel, clazz)
                        clazz
                       end
    end

    def self.needed_attributes
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
                  .permit self.needed_attributes
      end
      action
    end

    def init_from_needed
      {}
    end

    def all_attributes_from(other_model)
      other_model.attributes.slice(*self.class.needed_attributes.map(&:to_s))
    end

    def form_model(params={})
      @_form_model ||= begin
                         attributes = init_from_needed.merge(params)
                         model_instance = self.class.form_model_class.new
                         model_instance.instance_variable_set(:@_action, self)
                         model_instance.assign_attributes(attributes)
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

      SeriousBusiness::Actor.send(:define_method, method_name) do |params: {}, for_model: nil|
        child_class.build(actor_id: self.id, for_model: for_model, params: params)
      end
    end

    def cta_label
      I18n.t("serious_action.#{self.class.param_name}.cta")
    end

    def description
      content = I18n.t("serious_action.#{self.class.param_name}.description")
      if can?
        content
      else
        I18n.t("serious_action.description_with_failed_guards", description: content, reasons: full_guard_messages)
      end
    end

    def success_description
      custom_msg = I18n.t("serious_action.#{self.class.param_name}.success_description")
      return custom_msg unless custom_msg.starts_with? 'translation missing'
      content = I18n.t("serious_action.#{self.class.param_name}.description")
      I18n.t("serious_action.success_description", description: content)
    end

    def execute!
      unless can?
        form_model.errors.add(:base, description)
        return false
      end
      self.class.transaction do
        begin
          if self.class.needed_attributes.any? && !form_model.valid?
            return false
          end
          self.transient_affected_models = self.execute
          self.transient_affected_models.each do |model|
            model.errors.each do |key, error|
              error_key = if self.class.needed_attributes.include? key
                            key
                          else
                            :base
                          end
              form_model.errors.add error_key, error
            end
          end
          if form_model.errors.any?
            return false
          end
          self.save!
          self.transient_affected_models.each do |model|
            SeriousBusiness::Affected.create!(action: self, affected: model)
          end
          return true
        rescue Exception => e
          raise e
        end
      end
    end

    protected

    def execute
      raise "execute should be overwritten in subclass"
    end

    private

    def reset_form_model
      @_form_model = nil
    end
  end
end

