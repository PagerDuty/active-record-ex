# Allows choosing the subclass of a model
# via a passed :type parameter
# this is useful for using accepts_nested_attributes_for
# with subclassed associations
module ActiveRecordEx
  module PolymorphicBuild
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_eval do
        attr_accessible :type if respond_to?(:attr_accessible)

        class << self
          alias_method_chain :new, :typing
        end
      end
    end

    module ClassMethods
      def new_with_typing(attrs = {}, options = {})
        if attrs[:type] && (klass = attrs[:type].constantize) < self
          klass.new(attrs, options)
        elsif attrs[:type] && !((klass = attrs[:type].constantize) <= self)
          raise ArgumentError.new("Attempting to instantiate #{klass}, which is not a subclass of #{self}")
        else
          new_without_typing(attrs, options)
        end
      end
    end
  end
end
