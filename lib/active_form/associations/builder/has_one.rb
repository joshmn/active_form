module ActiveForm
  module Associations
    module Builder
      class HasOne < SingularAssociation # :nodoc:
        def self.macro
          :has_one
        end

        def self.valid_options(options)
          valid = super
          valid += [:as, :foreign_type] if options[:as]
          valid += [:ensuring_owner_was] if options[:dependent] == :destroy_async
          valid += [:through, :source, :source_type] if options[:through]
          valid += [:disable_joins] if options[:disable_joins] && options[:through]
          valid
        end

        def self.valid_dependent_options
          [:destroy, :destroy_async, :delete, :nullify, :restrict_with_error, :restrict_with_exception]
        end

        def self.define_callbacks(model, reflection)
          super
          add_touch_callbacks(model, reflection) if reflection.options[:touch]
        end

        def self.add_destroy_callbacks(model, reflection)
        end

        def self.define_validations(model, reflection)
          super
          if reflection.options[:required]
            model.validates_presence_of reflection.name, message: :required
          end
        end

        def self.touch_record(record, name, touch)

        end

        def self.add_touch_callbacks(model, reflection)

        end

        private_class_method :macro, :valid_options, :valid_dependent_options, :add_destroy_callbacks,
                             :define_callbacks, :define_validations, :add_touch_callbacks
      end
    end
  end
end
