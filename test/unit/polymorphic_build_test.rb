require 'test_helper'
require 'active-record-ex/polymorphic_build'

class PolymorphicBuildTest < ActiveSupport::TestCase
  class PolyBase < ActiveRecord::Base
    include ActiveRecordEx::PolymorphicBuild
    attr_accessor :type
  end

  class PolyChild < PolyBase
  end

  should 'instantiate an instance with the subclass passed in' do
    inst = PolyBase.new(type: PolyChild.to_s)
    assert_equal PolyChild, inst.class
  end

  should 'instantiate an instance with the class itself passed in' do
    inst = PolyBase.new(type: PolyBase.to_s)
    assert_equal PolyBase, inst.class
  end

  should 'throw an error if the passed in class is not a subclass' do
    assert_raise(ArgumentError) do
      PolyBase.new(type: ActiveRecord::Base.to_s)
    end
  end
end
