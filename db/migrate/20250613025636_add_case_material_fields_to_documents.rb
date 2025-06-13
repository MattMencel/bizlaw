class AddCaseMaterialFieldsToDocuments < ActiveRecord::Migration[8.0]
  def change
    # Enable pg_trgm extension for full-text search
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    add_column :documents, :category, :string
    add_column :documents, :access_level, :string, default: 'case_teams'
    add_column :documents, :team_restrictions, :jsonb, default: {}
    add_column :documents, :searchable_content, :text
    add_column :documents, :annotations, :jsonb, default: []
    add_column :documents, :tags, :jsonb, default: []

    # Add indexes for better query performance
    add_index :documents, :category
    add_index :documents, :access_level
    add_index :documents, [:documentable_type, :documentable_id, :category]
    
    # Add GIN index for JSONB fields for faster searching
    add_index :documents, :team_restrictions, using: :gin
    add_index :documents, :tags, using: :gin
    
    # Add full-text search index for searchable content
    add_index :documents, :searchable_content, opclass: :gin_trgm_ops, using: :gin
  end
end
