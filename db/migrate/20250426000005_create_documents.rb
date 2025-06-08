# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.column :document_type, :document_type, null: false
      t.column :status, :document_status, null: false, default: 'draft'
      t.string :file_url
      t.string :file_type
      t.integer :file_size
      t.datetime :finalized_at
      t.datetime :archived_at
      t.references :documentable, polymorphic: true, type: :uuid, null: false
      t.references :created_by, null: false, type: :uuid, foreign_key: { to_table: :users }

      t.timestamps
      t.datetime :deleted_at

      t.index :deleted_at
      t.index :document_type
      t.index :status
    end
  end
end
