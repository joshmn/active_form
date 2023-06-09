require "active_form/relation/delegation"
require 'active_form/associations'
require 'active_form/core'
require 'active_form/inheritance'
require 'active_form/reflection'
require 'active_form/relation'
require 'active_form/attributes'
require 'active_form/nested_attributes'
require 'active_form/association_relation'
require 'active_form/associations/association'
require 'active_form/associations/singular_association'
require 'active_form/associations/collection_association'
require 'active_form/associations/foreign_association'
require 'active_form/associations/collection_proxy'
require 'active_form/associations/builder'
require 'active_form/associations/builder/association'
require 'active_form/associations/builder/singular_association'
require 'active_form/associations/builder/collection_association'
require 'active_form/associations/builder/has_one'
require 'active_form/associations/builder/has_many'
require 'active_form/associations/has_many_association'
require 'active_form/associations/has_one_association'

require 'active_form/acts_like_model'
require 'active_form/from_model'
require 'active_form/from_params'

module ActiveForm
  class ActiveFormError < StandardError
  end
  class AssociationTypeMismatch < ActiveFormError
  end

  class Base
    include ActiveForm::Associations
    include ActiveModel::Model
    include ActiveModel::Validations
    include ActiveModel::Attributes
    include ActiveModel::AttributeAssignment
    include ActiveModel::AttributeMethods
    include ActiveModel::Callbacks
    include ActiveModel::Dirty
    extend  Relation::Delegation::DelegateCache
    include ActiveForm::Attributes

    include ActiveForm::Core
    include ActiveForm::Inheritance
    include ActiveForm::Reflection
    include ActiveForm::NestedAttributes

    include ActiveForm::ActsLikeModel
    include ActiveForm::FromParams
    include FromModel

    def init_internals
      @readonly                 = false
      @previously_new_record    = false
      @destroyed                = false
      @marked_for_destruction   = false
      @destroyed_by_association = nil
      @_start_transaction_state = nil
      @association_cache = {}
      klass = self.class

      @primary_key         = klass.primary_key
      @strict_loading      = false
      @strict_loading_mode = :all

      klass.define_attribute_methods
    end

    def initialize_internals_callback
    end

    def initialize(attributes = nil)
      @new_record = true
      @attributes = self.class._default_attributes.deep_dup

      init_internals
      initialize_internals_callback

      assign_attributes(attributes) if attributes

      yield self if block_given?
      _run_initialize_callbacks
    end

    class_attribute :inheritance_column, default: :form_type

    define_model_callbacks :initialize, only: [:after]
    define_model_callbacks :validation, only: [:before, :after]

    attribute :id, :integer
    attribute :_destroy, :boolean

    class_attribute :model
    class_attribute :primary_key, default: "id"
    class_attribute :model_name
    class_attribute :copy_attributes, default: false
    class_attribute :default_ignored_attributes, default: %w[id created_at updated_at]
    class_attribute :ignored_attributes, default: []

    def with_context(contexts = {})
      @context = OpenStruct.new(contexts)
      _reflections.each do |_, reflection|
        if instance = public_send(reflection.name)
          instance.with_context(@context)
        end
      end
      self
    end

    attr_reader :context

    def inspect
      # We check defined?(@attributes) not to issue warnings if the object is
      # allocated but not initialized.
      inspection = if defined?(@attributes) && @attributes
                     self.class.attribute_names.filter_map do |name|
                       if self.class.attribute_types.key?(name)
                         "#{name}: #{_read_attribute(name).inspect}"
                       end
                     end.join(", ")
                   else
                     "not initialized"
                   end

      "#<#{self.class} #{inspection}>"
    end

    def persisted?
      id.present? && id.to_i.positive?
    end

    def self.from_json(json)
      params = JSON.parse(json)
      from_params(params)
    end

    def valid?(options = {})
      run_callbacks(:validation) do
        options     = {} if options.blank?
        context     = options[:context]
        validations = [super(context)]

        validations.all?
      end
    end

    def invalid?(options = {})
      !valid?(options)
    end

    def to_key
      [id]
    end

    def self.model_name
      if model.is_a?(Symbol)
        ActiveModel::Name.new(self, nil, model.to_s)
      elsif model.present?
        ActiveModel::Name.new(self, nil, model.model_name.name.split('::').last)
      else
        name = self.name.demodulize.delete_suffix("Form")
        if name.blank?
          name = self.name
        end
        ActiveModel::Name.new(self, nil, name)
      end
    end

    def model_name
      self.class.model_name
    end

    def new_record?
      !persisted?
    end

    def self.distinct_value
      true
    end

    def marked_for_destruction?
      attributes['_destroy']
    end

    def destroy?
      _destroy
    end
  end
end
