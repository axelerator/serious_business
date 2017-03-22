module SeriousBusiness
  class BaseFormModel
    include ActiveModel::AttributeAssignment
    include ActiveModel::Validations

    def take_attributes_from(model, fields = nil)
      fields ||= @_action.class.needed_attributes.map(&:to_s)
      self.assign_attributes(model.attributes.slice(*fields))
    end

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
      @_action.class.needed_attributes.inject({}) do |sum, attr_name|
        sum[attr_name] = self.instance_variable_get("@#{attr_name}")
        sum
      end
    end
  end
end
