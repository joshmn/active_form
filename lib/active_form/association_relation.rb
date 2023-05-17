module ActiveForm
  class AssociationRelation < Relation # :nodoc:
    def initialize(klass, association, **)
      super(klass)
      @association = association
    end

    def proxy_association
      @association
    end

    def ==(other)
      other == records
    end

    def merge!(other, *rest) # :nodoc:
      # no-op #
    end

    private
    def _new(attributes, &block)
      @association.build(attributes, &block)
    end

    def _create(attributes, &block)
      @association.create(attributes, &block)
    end

    def _create!(attributes, &block)
      @association.create!(attributes, &block)
    end
  end
end
