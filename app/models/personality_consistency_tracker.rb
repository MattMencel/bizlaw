# frozen_string_literal: true

class PersonalityConsistencyTracker < ApplicationRecord
  include HasUuid
  include HasTimestamps

  # Associations
  belongs_to :case

  # Validations
  validates :personality_type, presence: true
  validates :response_history, presence: true
  validates :consistency_score, presence: true, 
                                numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Scopes
  scope :by_personality, ->(personality_type) { where(personality_type: personality_type) }
  scope :by_case, ->(case_id) { where(case_id: case_id) }
  scope :high_consistency, -> { where('consistency_score >= ?', 70) }
  scope :low_consistency, -> { where('consistency_score < ?', 50) }
  scope :recent, -> { order(created_at: :desc) }

  def consistent?
    consistency_score >= 70
  end

  def inconsistent?
    consistency_score < 50
  end

  def response_count
    response_history.length
  end

  def personality_traits
    PersonalityService.get_personality_traits(personality_type)
  rescue ArgumentError
    {}
  end
end