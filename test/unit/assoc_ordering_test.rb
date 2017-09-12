require 'test_helper'
require 'active-record-ex/assoc_ordering'

class OrderedAssoc < ActiveRecord::Base
  attr_accessor :name
  attr_accessor :order
  attr_accessor :has_orderd_assoc_id
end

class DestroyableAssoc < ActiveRecord::Base
  attr_accessor :name
  attr_accessor :order
  attr_accessor :has_orderd_assoc_id
end

class HasOrderedAssoc < ActiveRecord::Base
  include ActiveRecordEx::AssocOrdering

  has_many :ordered_assocs, order_on: :order
  accepts_nested_attributes_for :ordered_assocs, order_on: :order

  has_many :destroyable_assocs, order_on: :order
  accepts_nested_attributes_for :destroyable_assocs, order_on: :order, allow_destroy: true

  def save
  end
end


class AssocOrderingTest < ActiveSupport::TestCase
  context 'A class with ActiveREcord::AssocOrdering included' do
    setup { @model = HasOrderedAssoc.new }

    should 'order associations set as models' do
      assocs = [OrderedAssoc.new(name: 'first'), OrderedAssoc.new(name: 'second')]
      @model.ordered_assocs = assocs
      sorted = @model.ordered_assocs.sort_by(&:order)
      assert_equal 'first', sorted[0].name
      assert_equal 1, sorted[0].order
      assert_equal 'second', sorted[1].name
      assert_equal 2, sorted[1].order
    end

    should 'order associations set as attributes' do
      attrs = {ordered_assocs_attributes:
        [{name: 'first'}, {name: 'second'}]
      }
      expected_attrs = [{name: 'first', order: 1}, {name: 'second', order: 2}]
      @model.expects(:ordered_assocs_attributes_without_ordering=).with(expected_attrs)
      @model.update_attributes(attrs)
    end

    should 'not ignore marked-for-destroy association attributes for ordering that don\'t allow destroy' do
      attrs = {ordered_assocs_attributes:
        [{name: 'first', _destroy: true}, {name: 'second'}]
      }
      expected_attrs = [{name: 'first', _destroy: true, order: 1}, {name: 'second', order: 2}]
      @model.expects(:ordered_assocs_attributes_without_ordering=).with(expected_attrs)
      @model.update_attributes(attrs)
    end

    should 'ignore marked-for-destroy association attributes for ordering that allow destroy' do
      attrs = {destroyable_assocs_attributes:
        [{name: 'first', _destroy: true}, {name: 'second'}]
      }
      expected_attrs = [{name: 'first', _destroy: true}, {name: 'second', order: 1}]
      @model.expects(:destroyable_assocs_attributes_without_ordering=).with(expected_attrs)
      @model.update_attributes(attrs)
    end
  end
end
