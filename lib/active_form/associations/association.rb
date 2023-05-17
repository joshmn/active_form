module ActiveForm
  module Associations
    class Association # :nodoc:
      attr_reader :owner, :target, :reflection, :disable_joins

      delegate :options, to: :reflection

      def initialize(owner, reflection)
        reflection.check_validity!

        @owner, @reflection = owner, reflection
        @disable_joins = @reflection.options[:disable_joins] || false

        reset
        reset_scope
      end

      def reset
        @loaded = true
        @target = nil
        @stale_state = nil
      end

      def reset_negative_cache # :nodoc:
        reset if loaded? && target.nil?
      end
      # Reloads the \target and returns +self+ on success.
      # The QueryCache is cleared if +force+ is true.
      def reload(force = false)
        klass.connection.clear_query_cache if force && klass
        reset
        reset_scope
        load_target
        self unless target.nil?
      end

      def loaded?
        @loaded
      end
      # Asserts the \target has been loaded setting the \loaded flag to +true+.
      def loaded!
        @loaded = true
        @stale_state = stale_state
      end

      def stale_target?
        loaded? && @stale_state != stale_state
      end

      def target=(target)
        @target = target
        loaded!
      end

      def scope
        target
      end

      def reset_scope
        @association_scope = nil
      end

      # Set the inverse association, if possible
      def set_inverse_instance(record)
        if inverse = inverse_association_for(record)
          inverse.inversed_from(owner)
        end
        record
      end

      def klass
        reflection.klass
      end

      def extensions
        extensions = reflection.extensions

        if reflection.scope
          extensions |= reflection.scope_for(klass.unscoped, owner).extensions
        end

        extensions
      end

      def load_target
        @target = find_target if (@stale_state && stale_target?) || find_target?

        loaded! unless loaded?
        target
      rescue ActiveRecord::RecordNotFound
        reset
      end
      # We can't dump @reflection and @through_reflection since it contains the scope proc
      def marshal_dump
        ivars = (instance_variables - [:@reflection, :@through_reflection]).map { |name| [name, instance_variable_get(name)] }
        [@reflection.name, ivars]
      end

      def marshal_load(data)
        reflection_name, ivars = data
        ivars.each { |name, val| instance_variable_set(name, val) }
        @reflection = @owner.class._reflect_on_association(reflection_name)
      end

      def initialize_attributes(record, except_from_scope_attributes = nil) # :nodoc:
        except_from_scope_attributes ||= {}
        skip_assign = [reflection.foreign_key, reflection.type].compact
        assigned_keys = record.changed
        assigned_keys += except_from_scope_attributes.keys.map(&:to_s)
        attributes = {}.except!(*(assigned_keys - skip_assign))
        record.send(:_assign_attributes, attributes) if attributes.any?
        set_inverse_instance(record)
      end

      private
      # Reader and writer methods call this so that consistent errors are presented
      # when the association target class does not exist.
      def ensure_klass_exists!
        klass
      end

      def find_target
        scope = self.scope
        return scope.to_a if skip_statement_cache?(scope)

        sc = reflection.association_scope_cache(klass, owner) do |params|
          as = AssociationScope.create { params.bind }
          target_scope.merge!(as.scope(self))
        end

        binds = AssociationScope.get_bind_values(owner, reflection.chain)
        sc.execute(binds, klass.connection) do |record|
          set_inverse_instance(record)
          if owner.strict_loading_n_plus_one_only? && reflection.macro == :has_many
            record.strict_loading!
          else
            record.strict_loading!(false, mode: owner.strict_loading_mode)
          end
        end
      end

      def violates_strict_loading?
        return reflection.strict_loading? if reflection.options.key?(:strict_loading)

        false # owner.strict_loading? && !owner.strict_loading_n_plus_one_only?
      end

      # The scope for this association.
      #
      # Note that the association_scope is merged into the target_scope only when the
      # scope method is called. This is because at that point the call may be surrounded
      # by scope.scoping { ... } or unscoped { ... } etc, which affects the scope which
      # actually gets built.
      def association_scope
        klass
      end
      # Can be overridden (i.e. in ThroughAssociation) to merge in other scopes (i.e. the
      # through association's scope)
      def target_scope
        AssociationRelation.create(klass, self).merge!({})
      end

      def find_target?
        !loaded? && (!owner.new_record? || foreign_key_present?) && klass
      end

      def foreign_key_present?
        false
      end
      # Raises ActiveRecord::AssociationTypeMismatch unless +record+ is of
      # the kind of the class of the associated objects. Meant to be used as
      # a safety check when you are about to assign an associated record.
      def raise_on_type_mismatch!(record)
        unless record.is_a?(reflection.klass)
          fresh_class = reflection.class_name.safe_constantize
          unless fresh_class && record.is_a?(fresh_class)
            message = "#{reflection.class_name}(##{reflection.klass.object_id}) expected, "\
                "got #{record.inspect} which is an instance of #{record.class}(##{record.class.object_id})"
            raise ActiveRecord::AssociationTypeMismatch, message
          end
        end
      end

      def inverse_association_for(record)
        if invertible_for?(record)
          record.association(inverse_reflection_for(record).name)
        end
      end
      # Can be redefined by subclasses, notably polymorphic belongs_to
      # The record parameter is necessary to support polymorphic inverses as we must check for
      # the association in the specific class of the record.
      def inverse_reflection_for(record)
        reflection.inverse_of
      end
      # Returns true if inverse association on the given record needs to be set.
      # This method is redefined by subclasses.
      def invertible_for?(record)
        foreign_key_for?(record) && inverse_reflection_for(record)
      end
      # Returns true if record contains the foreign_key
      def foreign_key_for?(record)
        record._has_attribute?(reflection.foreign_key)
      end

      # This should be implemented to return the values of the relevant key(s) on the owner,
      # so that when stale_state is different from the value stored on the last find_target,
      # the target is stale.
      #
      # This is only relevant to certain associations, which is why it returns +nil+ by default.
      def stale_state
      end

      def build_record(attributes)
        reflection.build_association(attributes) do |record|
          initialize_attributes(record, attributes)
          yield(record) if block_given?
        end
      end

      # Returns true if statement cache should be skipped on the association reader.
      def skip_statement_cache?(scope)
        reflection.has_scope? ||
          scope.eager_loading? ||
          klass.scope_attributes? ||
          reflection.source_reflection.active_record.default_scopes.any?
      end

      def enqueue_destroy_association(options)
        job_class = owner.class.destroy_association_async_job

        if job_class
          owner._after_commit_jobs.push([job_class, options])
        end
      end

      def inversable?(record)
        record &&
          ((!record.persisted? || !owner.persisted?) || matches_foreign_key?(record))
      end

      def matches_foreign_key?(record)
        if foreign_key_for?(record)
          record.read_attribute(reflection.foreign_key) == owner.id ||
            (foreign_key_for?(owner) && owner.read_attribute(reflection.foreign_key) == record.id)
        else
          owner.read_attribute(reflection.foreign_key) == record.id
        end
      end
    end
  end
end
