class AddInstructorScoringToSettlementOffers < ActiveRecord::Migration[8.0]
  def change
    add_column :settlement_offers, :instructor_legal_reasoning_score, :integer
    add_column :settlement_offers, :instructor_factual_analysis_score, :integer
    add_column :settlement_offers, :instructor_strategic_thinking_score, :integer
    add_column :settlement_offers, :instructor_professionalism_score, :integer
    add_column :settlement_offers, :instructor_creativity_score, :integer
    add_column :settlement_offers, :instructor_quality_score, :integer
    add_column :settlement_offers, :instructor_feedback, :text
    add_column :settlement_offers, :scored_by_id, :uuid, null: true
    add_foreign_key :settlement_offers, :users, column: :scored_by_id
    add_column :settlement_offers, :scored_at, :datetime
    add_column :settlement_offers, :final_quality_score, :integer

    # Add constraints for score ranges (0-25 for individual categories, 0-125 for totals)
    add_check_constraint :settlement_offers, 
      "instructor_legal_reasoning_score >= 0 AND instructor_legal_reasoning_score <= 25", 
      name: "check_legal_reasoning_score_range"
    
    add_check_constraint :settlement_offers, 
      "instructor_factual_analysis_score >= 0 AND instructor_factual_analysis_score <= 25", 
      name: "check_factual_analysis_score_range"
    
    add_check_constraint :settlement_offers, 
      "instructor_strategic_thinking_score >= 0 AND instructor_strategic_thinking_score <= 25", 
      name: "check_strategic_thinking_score_range"
    
    add_check_constraint :settlement_offers, 
      "instructor_professionalism_score >= 0 AND instructor_professionalism_score <= 25", 
      name: "check_professionalism_score_range"
    
    add_check_constraint :settlement_offers, 
      "instructor_creativity_score >= 0 AND instructor_creativity_score <= 25", 
      name: "check_creativity_score_range"
    
    add_check_constraint :settlement_offers, 
      "instructor_quality_score >= 0 AND instructor_quality_score <= 125", 
      name: "check_instructor_quality_score_range"
    
    add_check_constraint :settlement_offers, 
      "final_quality_score >= 0 AND final_quality_score <= 125", 
      name: "check_final_quality_score_range"
  end
end
