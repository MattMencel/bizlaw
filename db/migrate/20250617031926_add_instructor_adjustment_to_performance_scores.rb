class AddInstructorAdjustmentToPerformanceScores < ActiveRecord::Migration[8.0]
  def change
    add_column :performance_scores, :instructor_adjustment, :integer
    add_column :performance_scores, :adjustment_reason, :text
    add_reference :performance_scores, :adjusted_by, null: true, type: :uuid, foreign_key: { to_table: :users }
    add_column :performance_scores, :adjusted_at, :datetime
  end
end
