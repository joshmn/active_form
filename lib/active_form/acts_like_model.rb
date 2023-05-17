module ActiveForm
  module ActsLikeModel
    extend ActiveSupport::Concern

    module ClassMethods
      def inherit_model_validations(model, *attributes)
        attributes.each do |attr|
          model._validators[attr].each do |validator|
            if validator.options.none?
              validates attr, validator.kind => true
            else
              validates attr, validator.kind => validator.options
            end
          end
        end
      end

      def acts_like_model(model, copy_attributes: false)
        self.model = model

        return unless copy_attributes

        model.columns_hash.each do |key, value|
          next if ignored_attributes.include?(key)
          next if default_ignored_attributes.include?(key)

          if value.type == :text
            attribute key.to_sym, :string
          else
            attribute key.to_sym, value.type
          end
          alias_method "#{key.to_sym}?", key.to_sym if value.type == :boolean
        end

        model._validators.each do |attribute_name, validators|
          next if model._reflect_on_association(attribute_name)

          validators.each do |validator|
            validates attribute_name, validator.kind => validator.options
          end
        end
      end

      def from_model(record)
        instance = new
        record.attributes.each do |k, v|
          instance.public_send("#{k}=", v) if instance.attributes.key?(k)
        end
        instance.id = record.id
        instance.map_model(record)
        instance
      end
    end

    def from_model(record)
      instance = self
      record.attributes.each do |k, v|
        instance.public_send("#{k}=", v) if instance.attributes.key?(k)
      end
      instance.id = record.id
      instance.map_model(record)
      instance
    end

    def map_model(record); end
  end
end
