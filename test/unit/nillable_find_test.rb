require 'test_helper'
require 'active-record-ex/many_to_many'
require 'active-record-ex/nillable_find'

class NillableFindTest < ActiveSupport::TestCase
  class Parent < ActiveRecord::Base
    include ActiveRecordEx::ManyToMany
    include ActiveRecordEx::NillableFind

    has_many :children
  end

  class Child < ActiveRecord::Base
  end

  context 'ActiveRecordEx::NillableFind' do
    context '#nillable_find' do
      setup do
        @parent = Parent.where('1=1')
      end
      # RC == relative complement
      should 'request the RC of the base scope in the parent scope when just passed nil' do
        2.times { Parent.create }
        child = @parent.children.create
        foo_child = @parent.children.create(foo: 'bar')
        assert_equal Parent.nillable_find([nil], Child.where(foo: 'bar')).children.all, []
      end

      should 'request the disjunct of the RC of base scope in parent scope and all children of non-nil ids' do
        # fetch IDs
        2.times { Parent.create }
        parent = Parent.first
        child = parent.children.create
        assert_equal Parent.nillable_find([parent.id, nil], Child.where(foo: 'bar')).children.all.to_a, [child]
      end

      should 'request nothing when passed no an empty set of ids' do
        child = Child.create(foo: 'bar')
        assert_equal Parent.nillable_find([], Child.where(foo: 'bar')).children.all.to_a, []
      end

      should 'request as a normal many-to-many when passed only normal ids' do
        parent = Parent.create
        child = parent.children.create
        foo_child = Child.create(foo: 'bar')
        assert_equal Parent.nillable_find([parent.id], Child.where(foo: 'bar')).children.all.to_a, [child]
      end
    end
  end
end
