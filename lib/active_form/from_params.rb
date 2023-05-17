module ActiveForm
  module FromParams
    extend ActiveSupport::Concern

    def from_params(params, additional_params = {})
      attributes_hash = params.merge(additional_params)

      instance = self
      attributes_hash.each do |k, v|
        if instance.attributes.key?(k.to_s)
          instance.public_send("#{k}=", v)
        elsif instance.respond_to?("#{k}=")
          instance.public_send("#{k}=", v)
        end

      end
      instance
    end

    module ClassMethods
      def from_params(params, additional_params = {})
        attributes_hash = params.merge(additional_params)

        instance = new
        attributes_hash.each do |k, v|
          if instance.attributes.key?(k.to_s)
            instance.public_send("#{k}=", v)
          elsif instance.respond_to?("#{k}=")
            instance.public_send("#{k}=", v)
          end
        end
        instance
      end
    end

  end
end
