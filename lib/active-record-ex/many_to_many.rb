# allows you to chain has_manys and belongs_tos
# eg: $esc_pol.escalation_rules.escalation_targets
# eg: $usr.schedules.escalation_policies
module ActiveRecordEx
  module ManyToMany
    class ModelArel < ActiveRecord::Relation
      def initialize(model)
        super(model.class, model.class.arel_table)
        @loaded = true
        @records = [model]
      end

      def reset
        # reset says "my currently loaded into memory models no longer currently represent this relation".
        # That's never true for a ModelArel, so we no-op
      end

      def pluck(key)
        key = key.name if key.respond_to? :name
        @records.map(&:"#{key}")
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def set_scope_and_options(scope, options)
        if scope.is_a?(Hash)
          options = scope
          scope   = nil
        end
        [scope, options]
      end

      def belongs_to(name, scope = nil, options = {})
        scope, options = set_scope_and_options(scope, options)
        subtypes = options.delete(:subtypes)
        if ActiveRecord::VERSION::MAJOR < 4
          super(name, options)
        else
          super
        end
        define_belongs_assoc(name, options.merge(subtypes: subtypes))
      end

      def has_many(name, scope = nil, options = {}, &extension)
        scope, options = set_scope_and_options(scope, options)
        if ActiveRecord::VERSION::MAJOR < 4
          super(name, options, &extension)
        else
          super
        end
        define_has_assoc(name.to_s.singularize, options)
      end

      def has_one(name, scope = nil, options = {}, &extension)
        scope, options = set_scope_and_options(scope, options)
        if ActiveRecord::VERSION::MAJOR < 4
          super(name, options, &extension)
        else
          super
        end
        define_has_assoc(name.to_s, options)
      end

      def singularize(method_name)
        define_method(method_name) do |*params|
          ModelArel.new(self).send(method_name, *params)
        end
      end

      protected

      def define_belongs_assoc(name, options)
        if options[:polymorphic] && options[:subtypes]
          define_polymorphic_assoc(name, options[:subtypes])
        elsif !options[:polymorphic]
          define_monomorphic_assoc(name, options)
        end
      end

      def define_has_assoc(name, options)
        if options[:through]
          define_through_assoc(name, options)
        else
          define_plain_has_assoc(name, options)
        end
      end

      def define_monomorphic_assoc(name, options)
        name = name.to_s.singularize
        klass_name = options[:class_name] || self.parent_string + name.camelize
        key_name = options[:foreign_key] || name.foreign_key

        method_name = name.pluralize.to_sym
        define_singleton_method(method_name) do
          klass = klass_name.constantize
          foreign_key = ActiveRecord::VERSION::MAJOR < 4 ? self.arel_table[key_name] : self.arel_table[key_name].name
          primary_keys = self.pluck(foreign_key).uniq
          # eg, Account.where(id: ids)
          klass.where(klass.primary_key => primary_keys)
        end
      end

      def define_polymorphic_assoc(name, subtypes)
        Array.wrap(subtypes).each do |subtype_klass|
          key_name = name.to_s.foreign_key
          type_key = "#{name.to_s}_type"
          type_val = subtype_klass.to_s

          method_name = subtype_klass.to_s.demodulize.underscore.pluralize.to_sym
          define_singleton_method(method_name) do
            foreign_key = ActiveRecord::VERSION::MAJOR < 4 ? self.arel_table[key_name] : self.arel_table[key_name].name
            primary_keys = self.where(type_key => type_val).pluck(foreign_key).uniq
            # eg, Account.where(id: ids)
            subtype_klass.where(subtype_klass.primary_key => primary_keys)
          end
        end
      end

      def define_plain_has_assoc(name, options)
        klass_name = options[:class_name] || self.parent_string + name.camelize

        conditions = {}
        if options[:as]
          type_key_name = "#{options[:as].to_s}_type"
          conditions[type_key_name] = self.to_s
          foreign_key_name = options[:as].to_s.foreign_key
        else
          foreign_key_name = options[:foreign_key] || self.to_s.foreign_key
        end

        method_name = name.pluralize.to_sym
        define_singleton_method(method_name) do
          primary_key = ActiveRecord::VERSION::MAJOR < 4 ? self.arel_table[self.primary_key] : self.arel_table[self.primary_key].name
          foreign_keys = self.pluck(primary_key).uniq

          other_klass = klass_name.constantize
          other_klass.where(conditions).where(foreign_key_name => foreign_keys)
        end
      end

      def define_through_assoc(name, options)
        through_method = options[:through].to_s.pluralize
        method_name = name.pluralize.to_sym
        define_singleton_method(method_name) do
          through_base = self.send(through_method)
          through_base.send(method_name)
        end
      end

      def parent_string
        parent = self.parent
        return '' if parent == Object
        "#{parent.to_s}::"
      end
    end
  end
end
