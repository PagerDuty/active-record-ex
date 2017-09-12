require 'test_helper'
require 'active-record-ex/assume_destroy'

class AssumeDestroyTest < ActiveSupport::TestCase
  class AssumesDestroy < ActiveRecord::Base
    include ActiveRecordEx::AssumeDestroy

    has_many :destroyees
    accepts_nested_attributes_for :destroyees,  assume_destroy: true
  end

  class Destroyee < ActiveRecord::Base
  end

  context 'ActiveRecordEx::AssumeDestroy' do
    setup do
      @subject = AssumesDestroy.create
      2.times { @subject.destroyees.create }
    end

    context 'preconditions in ActiveRecord' do
      should 'DELETE records marked for destruction' do
        attrs = []
        assert_equal @subject.destroyees.count, 2
        @subject.update_attributes(destroyees_attributes: attrs)
        assert_equal Destroyee.all, []
      end
    end

    should 'not mark any for destruction if subject is new' do
      @subject.stubs(:new_record?).returns(true)
      attrs = [{name: 'one'}]
      expected_attrs = [{name: 'one'}]
      assert_no_queries { @subject.destroyees_attributes = attrs }
    end

    should 'mark all associations for destruction when passed an empty array' do
      attrs = []
      expected_attrs = []
      @subject.destroyees.each {|d| expected_attrs << {id: d.id, _destroy: true} }
      @subject.expects(:destroyees_attributes_without_assume=).with(expected_attrs)
      @subject.destroyees_attributes = attrs
    end

    should 'mark all existing associations for destruction when passed an array of just new' do
      attrs = [{name: 'one'}]
      expected_attrs = attrs.dup
      @subject.destroyees.each {|d| expected_attrs << {id: d.id, _destroy: true} }
      @subject.expects(:destroyees_attributes_without_assume=).with(expected_attrs)
      @subject.destroyees_attributes = attrs
    end

    should 'not mark explicitly passed in associations for destruction' do
      attrs = [{name: 'one'}, {id: 1}]
      expected_attrs = [{name: 'one'}, {id: 1}, {id: 2, _destroy: true}]
      @subject.expects(:destroyees_attributes_without_assume=).with(expected_attrs)
      @subject.destroyees_attributes = attrs
    end

    should 'preserve existing marks for destruction' do
      attrs = [{name: 'one'}, {id: 1, _destroy: true}]
      expected_attrs = [{name: 'one'}, {id: 1, _destroy: true}, {id: 2, _destroy: true}]
      @subject.expects(:destroyees_attributes_without_assume=).with(expected_attrs)
      @subject.destroyees_attributes = attrs
    end
  end
end
