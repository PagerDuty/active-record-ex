module ActiveRecord
  class Relation
    def where_only(value)
      relation = clone
      relation.where_values = build_where(value)
      relation
    end

    def none
      self.where('1=0')
    end

    def disjunct(other)
      other_where = other.collapsed_where
      this_where = self.collapsed_where
      self.where_only(this_where.or(other_where))
    end

    # If self and other are viewed as sets
    # relative_complement represents everything
    # that's in other but NOT in self
    def relative_complement(other)
      this_where = self.collapsed_where
      other_where = other.collapsed_where
      self.where_only(this_where.not.and(other_where))
    end

    protected

    def collapsed_where
      values = self.where_values
      # You must pass in 1 instead of True Arel no longer
      # supports TrueClass
      # https://github.com/rails/rails/issues/20473
      values = [1] if values.empty?
      # FIXME: Needs to wrap string literal conditions (e.g., where("id > 1"))
      Arel::Nodes::And.new(values)
    end
  end
end
