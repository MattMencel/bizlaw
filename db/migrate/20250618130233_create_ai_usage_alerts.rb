class CreateAiUsageAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_usage_alerts, id: :uuid do |t|
      t.string :alert_type, null: false
      t.decimal :threshold_value, precision: 10, scale: 6, null: false
      t.decimal :current_value, precision: 10, scale: 6, null: false
      t.string :status, default: 'active', null: false
      t.text :message
      t.jsonb :metadata, default: {}, null: false
      
      t.datetime :acknowledged_at
      t.string :acknowledged_by
      t.datetime :resolved_at
      t.string :resolved_by
      t.datetime :deleted_at
      t.timestamps

      t.index :alert_type
      t.index :status
      t.index :created_at
      t.index :deleted_at
      t.index [:alert_type, :status], name: 'index_ai_usage_alerts_on_type_and_status'
    end
  end
end
