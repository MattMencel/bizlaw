class RemoveDifficultyLevelAndEstimatedTimeFromCaseTypes < ActiveRecord::Migration[8.0]
  def change
    remove_column :case_types, :difficulty_level, :string
    remove_column :case_types, :estimated_time, :integer
  end
end
