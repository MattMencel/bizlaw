class CreateCaseTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :case_types do |t|
      t.string :title
      t.text :description
      t.string :difficulty_level
      t.integer :estimated_time

      t.timestamps
    end
  end
end
