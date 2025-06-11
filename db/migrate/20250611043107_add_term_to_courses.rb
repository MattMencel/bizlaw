class AddTermToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :term_id, :uuid, null: true
    add_index :courses, :term_id
    add_foreign_key :courses, :terms
  end
end
