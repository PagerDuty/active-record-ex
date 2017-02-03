# extends accepts_nested_attributes_for
# by default, accepts_nested_attributes_for "allow_destroy"s,
# ie, will destroy associations if explicitly marked by _destroy: true
# this flips that, causing an association to be destroyed
# if it's not included in the updating attrs
module ActiveRecordEx
  module AssumeDestroy
    def self.included base
      base.extend(ClassMethods)
    end

    module ClassMethods
      def accepts_nested_attributes_for(assoc_name, options={})
        assume_destroy = options[:assume_destroy]
        options.delete(:assume_destroy)
        options[:allow_destroy] = assume_destroy

        super assoc_name, options

        return unless assume_destroy

        attrs_name = ("#{assoc_name.to_s}_attributes").to_sym
        setter_name = ("#{attrs_name.to_s}=").to_sym
        unassuming_setter_name = ("#{attrs_name.to_s}_without_assume=").to_sym
        assuming_setter_name = ("#{attrs_name.to_s}_with_assume=").to_sym

        define_method(assuming_setter_name) do |attrs|
          ids = attrs.map { |a| a['id'] || a[:id] }.compact
          assocs = self.send(assoc_name)
          dead_assocs = []
          # the ternary's 'cause Arel doesn't do the right thing with an empty array
          dead_assocs = assocs.where('id NOT IN (?)', ids.any? ? ids : '') unless self.new_record?
          dead_attrs = dead_assocs.map {|assoc| {id: assoc.id, _destroy: true }}

          attrs = attrs.concat(dead_attrs)
          self.send(unassuming_setter_name, attrs)
        end
        alias_method unassuming_setter_name, setter_name
        alias_method setter_name, assuming_setter_name
      end
    end
  end
end
