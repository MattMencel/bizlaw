# frozen_string_literal: true

class PerformanceScore < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :simulation
  belongs_to :team
  belongs_to :user, optional: true # null for team scores
  belongs_to :adjusted_by, class_name: "User", optional: true

  # Delegated associations
  delegate :case, to: :simulation

  # Validations
  validates :total_score, presence: true,
                         numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :scored_at, presence: true
  validates :score_type, presence: true, inclusion: { in: %w[individual team] }
  validates :score_breakdown, presence: true

  validates :settlement_quality_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 40 }, allow_nil: true
  validates :legal_strategy_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 30 }, allow_nil: true
  validates :collaboration_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 20 }, allow_nil: true
  validates :efficiency_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :speed_bonus, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :creative_terms_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true

  validate :user_present_for_individual_scores
  validate :user_absent_for_team_scores
  validate :user_belongs_to_team

  # Scopes
  scope :individual_scores, -> { where(score_type: "individual") }
  scope :team_scores, -> { where(score_type: "team") }
  scope :top_performers, -> { order(total_score: :desc) }
  scope :for_simulation, ->(sim) { where(simulation: sim) }

  # Instance methods
  def individual_score?
    score_type == "individual"
  end

  def team_score?
    score_type == "team"
  end

  def calculate_total_score!
    components = [
      settlement_quality_score || 0,
      legal_strategy_score || 0,
      collaboration_score || 0,
      efficiency_score || 0,
      speed_bonus || 0,
      creative_terms_score || 0
    ]

    base_total = components.sum
    adjustment = instructor_adjustment || 0
    
    self.total_score = [base_total + adjustment, 0].max # Ensure non-negative
    self.score_breakdown = build_score_breakdown
    save!
  end

  def performance_grade
    case total_score
    when 90..100 then "A"
    when 80..89 then "B"
    when 70..79 then "C"
    when 60..69 then "D"
    else "F"
    end
  end

  def performance_summary
    {
      grade: performance_grade,
      total_score: total_score,
      strengths: identify_strengths,
      improvement_areas: identify_improvement_areas,
      breakdown: score_breakdown
    }
  end

  def rank_in_simulation
    PerformanceScore.where(simulation: simulation, score_type: score_type)
                   .where("total_score > ?", total_score)
                   .count + 1
  end

  def percentile_in_simulation
    total_scores = PerformanceScore.where(simulation: simulation, score_type: score_type)
                                  .pluck(:total_score)
    return 100 if total_scores.length <= 1

    below_count = total_scores.count { |score| score < total_score }
    (below_count.to_f / total_scores.length * 100).round(1)
  end

  # Class methods
  def self.calculate_team_score!(simulation, team)
    individual_scores = where(simulation: simulation, team: team, score_type: "individual")

    return nil if individual_scores.empty?

    # Calculate averages for each component
    avg_settlement = individual_scores.average(:settlement_quality_score) || 0
    avg_legal = individual_scores.average(:legal_strategy_score) || 0
    avg_collaboration = individual_scores.average(:collaboration_score) || 0
    avg_efficiency = individual_scores.average(:efficiency_score) || 0
    avg_speed = individual_scores.average(:speed_bonus) || 0
    avg_creative = individual_scores.average(:creative_terms_score) || 0

    # Find or create team score
    team_score = find_or_initialize_by(
      simulation: simulation,
      team: team,
      user: nil,
      score_type: "team"
    )

    team_score.assign_attributes(
      settlement_quality_score: avg_settlement,
      legal_strategy_score: avg_legal,
      collaboration_score: avg_collaboration,
      efficiency_score: avg_efficiency,
      speed_bonus: avg_speed,
      creative_terms_score: avg_creative,
      scored_at: Time.current
    )

    team_score.calculate_total_score!
    team_score
  end

  def self.calculate_individual_score!(simulation, team, user)
    score = find_or_initialize_by(
      simulation: simulation,
      team: team,
      user: user,
      score_type: "individual"
    )

    calculator = PerformanceCalculator.new(simulation, team, user)

    score.assign_attributes(
      settlement_quality_score: calculator.settlement_quality_score,
      legal_strategy_score: calculator.legal_strategy_score,
      collaboration_score: calculator.collaboration_score,
      efficiency_score: calculator.efficiency_score,
      speed_bonus: calculator.speed_bonus,
      creative_terms_score: calculator.creative_terms_score,
      scored_at: Time.current
    )

    score.calculate_total_score!
    score
  end

  private

  def build_score_breakdown
    breakdown = {
      "settlement_quality" => {
        "score" => settlement_quality_score || 0,
        "max_points" => 40,
        "weight" => "40%"
      },
      "legal_strategy" => {
        "score" => legal_strategy_score || 0,
        "max_points" => 30,
        "weight" => "30%"
      },
      "collaboration" => {
        "score" => collaboration_score || 0,
        "max_points" => 20,
        "weight" => "20%"
      },
      "efficiency" => {
        "score" => efficiency_score || 0,
        "max_points" => 10,
        "weight" => "10%"
      },
      "speed_bonus" => {
        "score" => speed_bonus || 0,
        "max_points" => 10,
        "weight" => "Bonus"
      },
      "creative_terms" => {
        "score" => creative_terms_score || 0,
        "max_points" => 10,
        "weight" => "Bonus"
      }
    }

    # Add instructor adjustment if present
    if instructor_adjustment && instructor_adjustment != 0
      breakdown["instructor_adjustment"] = {
        "score" => instructor_adjustment,
        "max_points" => "Variable",
        "weight" => "Manual",
        "reason" => adjustment_reason,
        "adjusted_by" => adjusted_by&.full_name,
        "adjusted_at" => adjusted_at&.strftime("%Y-%m-%d")
      }
    end

    breakdown
  end

  def identify_strengths
    strengths = []

    if (settlement_quality_score || 0) >= 32 # 80% of 40
      strengths << "Settlement Strategy"
    end

    if (legal_strategy_score || 0) >= 24 # 80% of 30
      strengths << "Legal Reasoning"
    end

    if (collaboration_score || 0) >= 16 # 80% of 20
      strengths << "Team Collaboration"
    end

    if (efficiency_score || 0) >= 8 # 80% of 10
      strengths << "Process Efficiency"
    end

    strengths
  end

  def identify_improvement_areas
    areas = []

    if (settlement_quality_score || 0) < 24 # 60% of 40
      areas << "Settlement Strategy"
    end

    if (legal_strategy_score || 0) < 18 # 60% of 30
      areas << "Legal Reasoning"
    end

    if (collaboration_score || 0) < 12 # 60% of 20
      areas << "Team Collaboration"
    end

    if (efficiency_score || 0) < 6 # 60% of 10
      areas << "Process Efficiency"
    end

    areas
  end

  def user_present_for_individual_scores
    if score_type == "individual" && user.blank?
      errors.add(:user, "must be present for individual scores")
    end
  end

  def user_absent_for_team_scores
    if score_type == "team" && user.present?
      errors.add(:user, "must be absent for team scores")
    end
  end

  def user_belongs_to_team
    return unless user.present? && team.present?

    unless team.team_members.exists?(user: user)
      errors.add(:user, "must be a member of the specified team")
    end
  end
end
