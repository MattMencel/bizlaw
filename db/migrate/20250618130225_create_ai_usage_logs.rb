class CreateAiUsageLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_usage_logs, id: :uuid do |t|
      t.string :model, null: false
      t.decimal :cost, precision: 10, scale: 6, null: false, default: 0
      t.integer :response_time_ms, null: false
      t.integer :tokens_used, default: 0
      t.string :request_type, null: false
      t.boolean :error_occurred, default: false, null: false
      t.jsonb :metadata, default: {}, null: false

      t.datetime :deleted_at
      t.timestamps

      t.index :model
      t.index :request_type
      t.index :error_occurred
      t.index :created_at
      t.index :deleted_at
      t.index [:created_at, :cost], name: 'index_ai_usage_logs_on_created_at_and_cost'
    end
  end
end
