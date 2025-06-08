# frozen_string_literal: true

class Case < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  belongs_to :course, optional: true
  belongs_to :team
  has_many :case_teams, dependent: :destroy
  has_many :assigned_teams, through: :case_teams, source: :team
  has_many :documents, as: :documentable, dependent: :destroy
  has_many :case_events, dependent: :destroy

  # Helper methods for team roles
  def plaintiff_team
    case_teams.find_by(role: :plaintiff)&.team
  end

  def defendant_team
    case_teams.find_by(role: :defendant)&.team
  end

  # Validations
  validates :title, presence: true,
                   length: { maximum: 255 }
  validates :description, presence: true
  validates :status, presence: true
  validates :difficulty_level, presence: true
  validates :created_by_id, presence: true
  validates :updated_by_id, presence: true
  validates :reference_number, presence: true, uniqueness: true
  validates :plaintiff_info, presence: true
  validates :defendant_info, presence: true
  validates :legal_issues, presence: true
  validates :team_id, presence: true
  validate :must_have_plaintiff_and_defendant_teams

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
  scope :published, -> { where(status: :published) }
  scope :drafts, -> { where(status: :draft) }
  scope :archived, -> { where(status: :archived) }
  scope :search_by_title, ->(query) {
    where("LOWER(title) LIKE :query", query: "%#{query.downcase}%")
  }
  scope :created_by, ->(user) { where(created_by_id: user.id) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(case_type: type) }
  scope :by_course, ->(course_id) { where(course_id: course_id) }
  scope :accessible_by, ->(user) {
    case user.role
    when "admin", "instructor"
      all
    when "student"
      joins(:assigned_teams).where(teams: { id: user.team_ids })
    else
      none
    end
  }

  # Methods
  def publish!
    return false unless status_draft?

    update!(
      status: :published,
      published_at: Time.current
    )
  end

  def archive!
    return false unless status_published?

    update!(
      status: :archived,
      archived_at: Time.current
    )
  end

  def draft?
    status_draft?
  end

  def published?
    status_published?
  end

  def archived?
    status_archived?
  end

  def editable?
    draft? || (published? && !archived?)
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

  private

  # Callbacks
  before_validation :set_updated_by, if: :changed?

  def set_updated_by
    self.updated_by_id = created_by_id if created_by_id_changed?
  end

  def must_have_plaintiff_and_defendant_teams
    roles = case_teams.map(&:role)
    unless roles.include?("plaintiff") && roles.include?("defendant")
      errors.add(:base, "Case must have at least one plaintiff and one defendant team")
    end
  end
end
