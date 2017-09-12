require 'test_helper'
require 'active-record-ex/many_to_many'

class ManyToManyTest < ActiveSupport::TestCase
  class HasManied < ActiveRecord::Base
    include ActiveRecordEx::ManyToMany

    has_one :one
    has_many :simple_belongs_tos
    has_many :belongs_to_throughs, through: :simple_belongs_tos
    has_many :class_nameds, class_name: 'ManyToManyTest::SomeClassName'
    has_many :foreign_keyeds, foreign_key: :some_foreign_key_id
    has_many :aseds, as: :some_as

    singularize :ones
  end
  class SimpleBelongsTo < ActiveRecord::Base
    include ActiveRecordEx::ManyToMany

    belongs_to :has_manied
    has_many :belongs_to_throughs

    singularize :has_manieds
  end
  class BelongsToThrough < ActiveRecord::Base
    include ActiveRecordEx::ManyToMany

    belongs_to :has_manied
  end
  class SomeClassName < ActiveRecord::Base
    include ActiveRecordEx::ManyToMany

    belongs_to :some_name, class_name: 'ManyToManyTest::HasManied'
  end
  class ForeignKeyed < ActiveRecord::Base
    include ActiveRecordEx::ManyToMany

    belongs_to :has_manied, foreign_key: :some_foreign_key_id
  end
  class Ased < ActiveRecord::Base
    include ActiveRecordEx::ManyToMany

    belongs_to :some_as, polymorphic: true, subtypes: [HasManied]
  end
  class One < ActiveRecord::Base
  end

  context 'ActiveRecord::ManyToMany' do
    context '#has_one' do
      setup do
        @has_manied = HasManied.create
        @one = @has_manied.create_one
      end

      should 'handle the simple case correctly' do
        assert_equal HasManied.where('1=1').ones.to_a, [@one]
      end
    end

    context '#has_many' do
      setup do
        @has_manied = HasManied.create
        @simple_belongs_to = @has_manied.simple_belongs_tos.create
      end

      should 'handle the simple case correctly' do
        assert_equal HasManied.where('1=1').simple_belongs_tos.to_a, [@simple_belongs_to]
      end

      should 'handle the empty base case correctly' do
        assert_equal HasManied.where('1=1').none.simple_belongs_tos.to_a, []
      end

      should 'handle the multiple base ids case correctly' do
        second_has_manied = HasManied.create
        simple_belongs_to = second_has_manied.simple_belongs_tos.create
        assert_equal HasManied.where('1=1').simple_belongs_tos.to_a, [@simple_belongs_to, simple_belongs_to]
      end

      should 'chain queries for has_many through:' do
        belongs_to_through = @simple_belongs_to.belongs_to_throughs.create

        assert_equal HasManied.belongs_to_throughs.to_a, [belongs_to_through]
      end

      should 'not N+1 has_many through:' do
        assert_queries(3) do
          HasManied.where('1=1').belongs_to_throughs.to_a
        end
      end

      should 'use the class name passed in' do
        @has_manied.class_nameds.create
        assert_equal HasManied.where('1=1').class_nameds.first.class, ManyToManyTest::SomeClassName
      end

      should 'use the foreign key passed in' do
        foreign_keyed = @has_manied.foreign_keyeds.create
        assert_equal HasManied.where('1=1').foreign_keyeds.to_a, [foreign_keyed]
      end

      should 'use the as passed in' do
        ased = @has_manied.aseds.create
        assert_equal HasManied.where('1=1').aseds.to_a, [ased]
      end
    end

    context '#belongs_to' do
      should 'handle the simple case correctly' do
        has_manied = HasManied.create
        sbt = has_manied.simple_belongs_tos.create
        assert_equal SimpleBelongsTo.where('1=1').has_manieds.to_a, [has_manied]
      end

      should 'use the class name passed in' do
        has_manied = HasManied.create
        scn = SomeClassName.create(some_name_id: has_manied.id)
        assert_equal SomeClassName.where('1=1').some_names.to_a, [has_manied]
      end

      should 'use the foreign key passed in' do
        has_manied = HasManied.create
        foreign_keyed = ForeignKeyed.create(has_manied: has_manied)
        assert_equal ForeignKeyed.where('1=1').has_manieds.to_a, [has_manied]
      end

      should 'handle polymorphic belongs_to' do
        has_manied = HasManied.create
        ased = Ased.create(some_as: has_manied)
        assert_equal Ased.where('1=1').has_manieds.to_a, [has_manied]
      end
    end

    context '#singularize' do
      should 'work for belongs_tos without triggering an extra query' do
        @model = SimpleBelongsTo.new
        @model.stubs(:has_manied_id).returns(42)
        @arel = HasManied.all
        assert_queries(1) { @model.has_manieds.to_a }
      end

      should 'work for has_ones without triggering an extra query' do
        @model = HasManied.new
        @model.stubs(:id).returns(42)
        @arel = One.all
        assert_queries(1) {@model.ones.to_a}
      end
    end
  end
end
