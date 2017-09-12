ActiveRecord::Schema.define do
  execute('PRAGMA foreign_keys = ON;')
  create_table 'assumes_destroys' do |t|
  end

  create_table "destroyees" do |t|
    t.integer :assumes_destroy_id
    t.string :name
  end

  create_table 'parents' do |t|
  end

  create_table "children" do |t|
    t.integer :parent_id
    t.string :foo
  end

  create_table 'has_manieds' do |t|
  end

  create_table 'has_ordered_assocs' do |t|
  end

  create_table 'ordered_assocs' do |t|
  end

  create_table 'simple_belongs_tos' do |t|
    t.integer :has_manied_id
  end

  create_table 'belongs_to_throughs' do |t|
    t.integer :simple_belongs_to_id
  end

  create_table 'some_class_names' do |t|
    t.integer :some_name_id
    t.integer :has_manied_id
  end

  create_table 'foreign_keyeds' do |t|
    t.integer :has_manied
  end
  # https://stackoverflow.com/questions/1884818/how-do-i-add-a-foreign-key-to-an-existing-sqlite-3-6-21-table
  execute("ALTER TABLE foreign_keyeds ADD COLUMN some_foreign_key_id INTEGER REFERENCES has_manieds(id)")

  create_table 'ones' do |t|
    t.integer :has_manied_id
  end

  create_table 'aseds' do |t|
    t.string :some_as_type
    t.integer :some_as_id
  end

  create_table 'belongs_tos' do |t|
    t.integer :has_manied_id
  end

  create_table 'poly_bases' do |t|
    t.string :type
  end
end
