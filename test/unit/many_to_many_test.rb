require 'test_helper'
require 'active-record-ex/many_to_many'

class ManyToManyTest < ActiveSupport::TestCase
  # Declare classes first to avoid circular dependencies
  class HasManied < StubModel; end
  class SomeClassNamedByClass < StubModel; end
  class HasManied < StubModel
    include ActiveRecordEx::ManyToMany

    has_one :one
    has_many :simple_belongs_tos
    has_many :belongs_to_throughs, through: :simple_belongs_tos
    has_many :class_nameds, class_name: 'ManyToManyTest::SomeClassName'
    has_many :class_nameds_by_class, class_name: ManyToManyTest::SomeClassNamedByClass
    has_many :foreign_keyeds, foreign_key: :some_foreign_key_id
    has_many :aseds, as: :some_as

    singularize :ones
  end
  class SimpleBelongsTo < StubModel
    include ActiveRecordEx::ManyToMany

    belongs_to :has_manied
    has_many :belongs_to_throughs

    singularize :has_manieds
  end
  class BelongsToThrough < StubModel
    include ActiveRecordEx::ManyToMany

    belongs_to :has_manied
  end
  class SomeClassName < StubModel
    include ActiveRecordEx::ManyToMany

    belongs_to :some_name, class_name: 'ManyToManyTest::HasManied'
  end
  class SomeClassNamedByClass < StubModel
    include ActiveRecordEx::ManyToMany

    belongs_to :some_name, class_name: ManyToManyTest::HasManied
  end
  class ForeignKeyed < StubModel
    include ActiveRecordEx::ManyToMany

    belongs_to :has_manied, foreign_key: :some_foreign_key_id
  end
  class Ased < StubModel
    include ActiveRecordEx::ManyToMany

    belongs_to :some_as, polymorphic: true, subtypes: [HasManied]
  end
  class One < StubModel
  end

  context 'ActiveRecord::ManyToMany' do
    context '#has_one' do
      setup { @arel = HasManied.scoped }
      should 'handle the simple case correctly' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [{id: 1}])
        db_expects(@arel, ['SELECT `ones`.* FROM `ones`  WHERE `ones`.`has_manied_id` IN (1)', 'ManyToManyTest::One Load'])
        @arel.ones.to_a
      end
    end

    context '#has_many' do
      setup { @arel = HasManied.scoped }

      should 'handle the simple case correctly' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [id: 1])
        db_expects(@arel, ['SELECT `simple_belongs_tos`.* FROM `simple_belongs_tos`  WHERE `simple_belongs_tos`.`has_manied_id` IN (1)', 'ManyToManyTest::SimpleBelongsTo Load'])
        @arel.simple_belongs_tos.to_a
      end

      should 'handle the empty base case correctly' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds`  WHERE (1=0)'], [])
        db_expects(@arel, ['SELECT `simple_belongs_tos`.* FROM `simple_belongs_tos`  WHERE 1=0', 'ManyToManyTest::SimpleBelongsTo Load'])
        @arel.none.simple_belongs_tos.to_a
      end

      should 'handle the multiple base ids case correctly' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [{id: 1}, {id: 2}])
        db_expects(@arel, ['SELECT `simple_belongs_tos`.* FROM `simple_belongs_tos`  WHERE `simple_belongs_tos`.`has_manied_id` IN (1, 2)', 'ManyToManyTest::SimpleBelongsTo Load'])
        @arel.simple_belongs_tos.to_a
      end

      should 'chain queries for has_many through:' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [{id: 1}])
        db_expects(@arel, ['SELECT `simple_belongs_tos`.`id` FROM `simple_belongs_tos`  WHERE `simple_belongs_tos`.`has_manied_id` IN (1)'], [{id: 1}])
        db_expects(@arel, ['SELECT `belongs_to_throughs`.* FROM `belongs_to_throughs`  WHERE `belongs_to_throughs`.`simple_belongs_to_id` IN (1)', 'ManyToManyTest::BelongsToThrough Load'])

        @arel.belongs_to_throughs.to_a
      end

      should 'not N+1 has_many through:' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [{id: 1}, {id: 2}])
        db_expects(@arel, ['SELECT `simple_belongs_tos`.`id` FROM `simple_belongs_tos`  WHERE `simple_belongs_tos`.`has_manied_id` IN (1, 2)'], [{id: 1}, {id: 2}])
        db_expects(@arel, ['SELECT `belongs_to_throughs`.* FROM `belongs_to_throughs`  WHERE `belongs_to_throughs`.`simple_belongs_to_id` IN (1, 2)', 'ManyToManyTest::BelongsToThrough Load'])

        @arel.belongs_to_throughs.to_a
      end

      should 'use the class name passed in' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [id: 1])
        db_expects(@arel, ['SELECT `some_class_names`.* FROM `some_class_names`  WHERE `some_class_names`.`has_manied_id` IN (1)', 'ManyToManyTest::SomeClassName Load'])
        @arel.class_nameds.to_a
      end

      should 'support class references for name' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [id: 1])
        db_expects(@arel, ['SELECT `some_class_names`.* FROM `some_class_names`  WHERE `some_class_names`.`has_manied_id` IN (1)', 'ManyToManyTest::SomeClassName Load'])
        @arel.class_nameds_by_class.to_a
      end

      should 'use the foreign key passed in' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [id: 1])
        db_expects(@arel, ['SELECT `foreign_keyeds`.* FROM `foreign_keyeds`  WHERE `foreign_keyeds`.`some_foreign_key_id` IN (1)', 'ManyToManyTest::ForeignKeyed Load'])
        @arel.foreign_keyeds.to_a
      end

      should 'use the as passed in' do
        db_expects(@arel, ['SELECT `has_manieds`.`id` FROM `has_manieds` '], [id: 1])
        db_expects(@arel, ['SELECT `aseds`.* FROM `aseds`  WHERE `aseds`.`some_as_type` = \'ManyToManyTest::HasManied\' AND `aseds`.`some_as_id` IN (1)', 'ManyToManyTest::Ased Load'])
        @arel.aseds.to_a
      end
    end

    context '#belongs_to' do
      should 'handle the simple case correctly' do
        @arel = SimpleBelongsTo.scoped
        db_expects(@arel, ['SELECT `simple_belongs_tos`.`has_manied_id` FROM `simple_belongs_tos` '], [has_manied_id: 1])
        db_expects(@arel, ['SELECT `has_manieds`.* FROM `has_manieds`  WHERE `has_manieds`.`id` IN (1)', 'ManyToManyTest::HasManied Load'])
        @arel.has_manieds.to_a
      end

      should 'use the class name passed in' do
        @arel = SomeClassName.scoped
        db_expects(@arel, ['SELECT `some_class_names`.`some_name_id` FROM `some_class_names` '], [some_name_id: 1])
        db_expects(@arel, ['SELECT `has_manieds`.* FROM `has_manieds`  WHERE `has_manieds`.`id` IN (1)', 'ManyToManyTest::HasManied Load'])
        @arel.some_names.to_a
      end

      should 'support class references for name' do
        @arel = SomeClassNamedByClass.scoped
        db_expects(@arel, ['SELECT `some_class_names`.`some_name_id` FROM `some_class_names` '], [some_name_id: 1])
        db_expects(@arel, ['SELECT `has_manieds`.* FROM `has_manieds`  WHERE `has_manieds`.`id` IN (1)', 'ManyToManyTest::HasManied Load'])
        @arel.some_names.to_a
      end
      
      should 'use the foreign key passed in' do
        @arel = ForeignKeyed.scoped
        db_expects(@arel, ['SELECT `foreign_keyeds`.`some_foreign_key_id` FROM `foreign_keyeds` '], [some_foreign_key_id: 1])
        db_expects(@arel, ['SELECT `has_manieds`.* FROM `has_manieds`  WHERE `has_manieds`.`id` IN (1)', 'ManyToManyTest::HasManied Load'])
        @arel.has_manieds.to_a
      end

      should 'handle polymorphic belongs_to' do
        @arel = Ased.scoped
        db_expects(@arel, ['SELECT `aseds`.`some_as_id` FROM `aseds`  WHERE `aseds`.`some_as_type` = \'ManyToManyTest::HasManied\''], [some_as_id: 1])
        db_expects(@arel, ['SELECT `has_manieds`.* FROM `has_manieds`  WHERE `has_manieds`.`id` IN (1)', 'ManyToManyTest::HasManied Load'])
        @arel.has_manieds.to_a
      end
    end

    context '#singularize' do
      should 'work for belongs_tos without triggering an extra query' do
        @model = SimpleBelongsTo.new
        @model.stubs(:has_manied_id).returns(42)
        @arel = HasManied.scoped
        db_expects(@arel, ['SELECT `has_manieds`.* FROM `has_manieds`  WHERE `has_manieds`.`id` IN (42)', 'ManyToManyTest::HasManied Load'])
        @model.has_manieds.to_a
      end

      should 'work for has_ones without triggering an extra query' do
        @model = HasManied.new
        @model.stubs(:id).returns(42)
        @arel = One.scoped
        db_expects(@arel, ['SELECT `ones`.* FROM `ones`  WHERE `ones`.`has_manied_id` IN (42)', 'ManyToManyTest::One Load'])
        @model.ones.to_a
      end
    end
  end
end
