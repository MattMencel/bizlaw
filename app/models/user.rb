# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :timeoutable,
    :omniauthable, omniauth_providers: [:google_oauth2]
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  has_many :team_members, dependent: :destroy
  has_many :teams, through: :team_members
  has_many :cases, through: :teams
  has_many :documents, foreign_key: :created_by_id
  has_many :owned_teams, class_name: "Team", foreign_key: :owner_id, dependent: :destroy

  # Organization association
  belongs_to :organization, optional: true, counter_cache: true

  # Course associations
  has_many :taught_courses, class_name: "Course", foreign_key: :instructor_id, dependent: :destroy
  has_many :course_enrollments, dependent: :destroy
  has_many :enrolled_courses, through: :course_enrollments, source: :course

  # Invitation associations
  has_many :sent_invitations, class_name: "Invitation", as: :invited_by, dependent: :destroy

  # Performance tracking associations
  has_many :performance_scores, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: {
    with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/,
    message: "must be a valid email address"
  }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true
  validates :roles, presence: true
  validate :roles_must_be_valid

  # Multiple roles support
  AVAILABLE_ROLES = %w[student instructor admin org_admin].freeze

  # Keep the enum for backward compatibility but add roles array support
  enum :role, {student: "student", instructor: "instructor", admin: "admin"}, prefix: true

  # Scopes for multiple roles
  scope :by_role, ->(role) { where("? = ANY(roles)", role) }
  scope :instructors, -> { where("'instructor' = ANY(roles)") }
  scope :students, -> { where("'student' = ANY(roles)") }
  scope :admins, -> { where("'admin' = ANY(roles)") }
  scope :org_admins, -> { where("'org_admin' = ANY(roles)") }
  scope :search_by_name, ->(query) {
    where("LOWER(first_name) LIKE :query OR LOWER(last_name) LIKE :query",
      query: "%#{query.downcase}%")
  }

  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    full_name
  end

  def initials
    "#{first_name.first}#{last_name.first}".upcase
  end

  def active_for_authentication?
    super && !deleted?
  end

  def student?
    has_role?("student")
  end

  def instructor?
    has_role?("instructor")
  end

  def admin?
    has_role?("admin")
  end

  def org_admin?
    has_role?("org_admin")
  end

  # Multiple roles methods
  def has_role?(role_name)
    roles.include?(role_name.to_s)
  end

  def add_role(role_name)
    return false unless AVAILABLE_ROLES.include?(role_name.to_s)
    return true if has_role?(role_name)

    self.roles = (roles + [role_name.to_s]).uniq
    save
  end

  # Navigation helper methods

  def can_access_case?(case_obj)
    return false unless case_obj
    cases.include?(case_obj) || admin? || instructor?
  end

  def can_access_team?(team_obj)
    return false unless team_obj
    teams.include?(team_obj) || admin? || instructor?
  end

  def role_in_case(case_obj)
    return "admin" if admin?
    return "instructor" if instructor?

    team = case_obj.teams.joins(:users).where(users: {id: id}).first
    team&.team_type&.humanize || "Student"
  end

  def role_in_team(team_obj)
    return "admin" if admin?
    return "instructor" if instructor?

    team_member = team_members.find_by(team: team_obj)
    team_member&.role&.humanize || "Member"
  end

  # Available cases for navigation
  def available_cases
    cases.includes(:teams, :users)
  end

  # Recently viewed cases (placeholder for now)
  def recently_viewed_cases
    # This would typically be tracked in a separate table or cache
    # For now, return empty relation
    cases.none
  end

  def remove_role(role_name)
    return false unless has_role?(role_name)

    self.roles = roles - [role_name.to_s]
    save
  end

  def role_names
    roles.join(", ").humanize
  end

  def primary_role
    # Return the first non-org_admin role, or 'student' as default
    (roles - ["org_admin"]).first || "student"
  end

  def professional?
    false
  end

  def can_manage_team?(team)
    admin? || org_admin? || team.owner_id == id || team_members.exists?(team: team, role: :manager)
  end

  def can_manage_organization?(organization)
    return false unless organization
    admin? || (org_admin? && organization_id == organization.id)
  end

  def can_assign_org_admin?
    return false unless organization
    admin? || (org_admin? && organization_id.present?)
  end

  def avatar_url
    # TODO: Implement avatar support (Gravatar, file upload, etc.)
    nil
  end

  # JWT methods
  def jwt_payload
    {
      user_id: id,
      email: email,
      role: role,
      full_name: full_name
    }
  end

  # Callbacks
  before_validation :downcase_email
  before_create :enforce_license_limits
  after_create :assign_first_instructor_as_org_admin

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.role = "student"
      user.roles = ["student"]
      # No avatar_url assignment
    end
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def enforce_license_limits
    return if Rails.application.config.skip_license_enforcement
    return unless organization

    enforcement_service = LicenseEnforcementService.new(organization: organization)

    begin
      enforcement_service.enforce_user_limit!(role)
    rescue LicenseEnforcementService::LicenseLimitExceeded => e
      errors.add(:base, e.message)
      throw :abort
    end
  end

  def license_enforcement
    @license_enforcement ||= LicenseEnforcementService.new(user: self)
  end

  def can_access_feature?(feature_name)
    license_enforcement.can_access_feature?(feature_name)
  end

  def assign_first_instructor_as_org_admin
    return unless instructor? && organization
    return if organization.users.org_admins.exists?

    add_role("org_admin")
  end

  def roles_must_be_valid
    return if roles.blank?

    invalid_roles = roles - AVAILABLE_ROLES
    if invalid_roles.any?
      errors.add(:roles, "contains invalid roles: #{invalid_roles.join(", ")}")
    end

    # Ensure at least one primary role (student, instructor, or admin)
    primary_roles = roles & %w[student instructor admin]
    if primary_roles.empty?
      errors.add(:roles, "must include at least one primary role (student, instructor, or admin)")
    end
  end
end
