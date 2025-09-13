class CreateAnnotations < ActiveRecord::Migration[8.0]
  def change
    create_table :annotations, id: :uuid do |t|
      t.text :content
      t.references :document, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.decimal :x_position, precision: 10, scale: 2
      t.decimal :y_position, precision: 10, scale: 2
      t.integer :page_number
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :annotations, [:document_id, :page_number]
    add_index :annotations, :deleted_at
  end
end
