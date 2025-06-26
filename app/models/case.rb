# frozen_string_literal: true

class Case < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  belongs_to :course
  has_many :simulations, dependent: :destroy
  has_many :teams, through: :simulations
  has_many :users, through: :teams
  has_many :documents, as: :documentable, dependent: :destroy
  has_many :case_events, dependent: :destroy

  # Helper methods for team roles
  def plaintiff_teams
    teams.where(role: :plaintiff)
  end

  def defendant_teams
    teams.where(role: :defendant)
  end

  def plaintiff_team
    plaintiff_teams.first
  end

  def defendant_team
    defendant_teams.first
  end

  # Validations
  validates :title, presence: true,
    length: {maximum: 255}
  validates :description, presence: true
  validates :status, presence: true
  validates :difficulty_level, presence: true
  validates :reference_number, presence: true, uniqueness: true
  validates :plaintiff_info, presence: true
  validates :defendant_info, presence: true
  validates :legal_issues, presence: true
  # validate :must_have_plaintiff_and_defendant_teams

  # Enums
  enum :status, {
    not_started: "not_started",
    in_progress: "in_progress",
    submitted: "submitted",
    reviewed: "reviewed",
    completed: "completed"
  }, prefix: :status

  enum :difficulty_level, {
    beginner: "beginner",
    intermediate: "intermediate",
    advanced: "advanced"
  }, prefix: :difficulty_level

  enum :case_type, {
    sexual_harassment: "sexual_harassment",
    discrimination: "discrimination",
    wrongful_termination: "wrongful_termination",
    contract_dispute: "contract_dispute",
    intellectual_property: "intellectual_property"
  }, prefix: :case_type

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_difficulty, ->(level) { where(difficulty_level: level) }
  scope :in_progress_cases, -> { where(status: :in_progress) }
  scope :submitted_cases, -> { where(status: :submitted) }
  scope :completed_cases, -> { where(status: :completed) }
  scope :active, -> { where.not(status: :completed) }
  scope :search_by_title, ->(query) {
    where("LOWER(title) LIKE :query", query: "%#{query.downcase}%")
  }
  scope :created_by, ->(user) { where(created_by_id: user.id) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(case_type: type) }
  scope :by_course, ->(course_id) { where(course_id: course_id) }
  scope :accessible_by, ->(user) {
    return all if user.admin?

    if user.instructor?
      # Instructors can only access cases in courses they teach
      joins(:course).where(course: {instructor: user})
    elsif user.student?
      # Students can only access cases where they are assigned to teams
      joins(:teams).where(teams: {id: user.team_ids})
    else
      none
    end
  }

  # Methods
  def start!
    return false unless status_not_started?

    update!(
      status: :in_progress,
      published_at: Time.current
    )
  end

  def submit!
    return false unless status_in_progress?

    update!(
      status: :submitted
    )
  end

  def complete!
    return false unless status_reviewed?

    update!(
      status: :completed
    )
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def published?
    published_at.present?
  end

  def archived?
    archived_at.present?
  end

  def editable?
    !archived? && (status_not_started? || status_in_progress?)
  end

  def display_name
    title
  end

  def team_for_role(role)
    teams.find_by(role: role)
  end

  def started?
    !status_not_started?
  end

  def completed?
    status_completed?
  end

  def can_submit?
    status_in_progress?
  end

  def can_review?
    status_submitted?
  end

  # Navigation helper methods
  def user_team_for(user)
    teams.joins(:users).where(users: {id: user.id}).first
  end

  def status_for_user(user)
    # This could be more sophisticated based on the user's actual status in the case
    # For now, return the case status
    status
  end

  def current_phase
    # This would come from the active simulation or case state
    active_simulation&.current_phase || "Preparation"
  end

  def current_round
    # This would come from the active simulation
    active_simulation&.current_round || 1
  end

  def total_rounds
    # This would come from the active simulation configuration
    active_simulation&.total_rounds || 6
  end

  # Helper method to get the active simulation
  # Returns the first active simulation, or the most recent one if none are active
  def active_simulation
    simulations.find { |sim| sim.active? } || simulations.order(:created_at).last
  end

  def team_status_for_user(user)
    # This would be more sophisticated in a real implementation
    # For now, return a default status
    "active"
  end

  def team_status(team = nil)
    # Return the status of a specific team in this case
    "active"
  end

  def upcoming_deadlines
    # This would return deadlines for the case
    # For now, return empty array
    []
  end

  def can_be_deleted?
    # Business rule: Only cases in 'not_started' status can be deleted
    return false unless status_not_started?

    # Business rule: Cannot delete if there are teams with student members
    !teams.any? { |team| team.has_student_members? }
  end

  def deletion_error_message
    return "Case can only be deleted when in 'Not Started' status" unless status_not_started?
    return "Cannot delete case with teams that have student members" if teams.any? { |team| team.has_student_members? }
    nil
  end

  private

  # Callbacks
  before_validation :set_updated_by, if: :changed?
  before_validation :set_reference_number, on: :create

  def set_updated_by
    self.updated_by_id = created_by_id if created_by_id_changed?
  end

  def set_reference_number
    return if reference_number.present?

    self.reference_number = "CASE-#{Date.current.year}-#{SecureRandom.hex(3).upcase}"
  end

  def must_have_plaintiff_and_defendant_teams
    roles = teams.distinct.pluck(:role)
    unless roles.include?("plaintiff") && roles.include?("defendant")
      errors.add(:base, "Case must have at least one plaintiff and one defendant team")
    end
  end
end
