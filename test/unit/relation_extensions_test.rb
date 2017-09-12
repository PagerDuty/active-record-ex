require 'test_helper'

class RelationExtensionsTest < ActiveSupport::TestCase
  class HasManied < ActiveRecord::Base
    has_many :belongs_tos
  end

  class BelongsTo < ActiveRecord::Base
    belongs_to :has_manied
    attr_accessor :has_manied_id
  end

  context '#relative_complement' do
    setup do
      @hm1 = HasManied.new
      @hm2 = HasManied.new
      @bt1 = @hm1.belongs_tos.new
    end

    context 'disjoint set' do
      should 'return all belongs_tos' do
        assert_equal @hm1.belongs_tos.all, @hm2.belongs_tos.relative_complement(@hm1.belongs_tos)
      end
    end

    context 'identical set' do
      should 'return nothing' do
        assert_empty @hm1.belongs_tos.relative_complement(@hm1.belongs_tos)
      end
    end

    context 'subset' do
      should 'return all other belongs_tos' do
        assert_equal @hm1.belongs_tos.where('id <> ?', @bt1.id).all, BelongsTo.where(id: @bt1.id).relative_complement(@hm1.belongs_tos).all
      end
    end

    context 'by empty set' do
      should 'return all belongs_tos' do
        assert_equal @hm1.belongs_tos.all, BelongsTo.where(id: -1).relative_complement(@hm1.belongs_tos)
      end
    end

    context 'of empty set' do
      should 'return nothing' do
        assert_empty @hm1.belongs_tos.relative_complement(BelongsTo.where(id: -1))
      end
    end

    context 'by unconditional' do
      should 'return nothing' do
        assert_equal true, BelongsTo.unscoped.relative_complement(@hm1.belongs_tos).empty?
      end
    end

    context 'of unconditional' do
      should 'return all belongs_tos' do
        assert_equal @hm2.belongs_tos.all, @hm1.belongs_tos.relative_complement(BelongsTo.where('1=1'))
      end
    end
  end
end
