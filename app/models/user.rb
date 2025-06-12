# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :timeoutable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  include HasUuid
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

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true

  # Enums - using PostgreSQL native enum type
  enum :role, { student: "student", instructor: "instructor", admin: "admin" }, prefix: true

  # Scopes
  scope :by_role, ->(role) { where(role: role) }
  scope :instructors, -> { where(role: :instructor) }
  scope :students, -> { where(role: :student) }
  scope :admins, -> { where(role: :admin) }
  scope :org_admins, -> { where(org_admin: true) }
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

  def active_for_authentication?
    super && !deleted?
  end

  def student?
    role_student?
  end

  def instructor?
    role_instructor?
  end

  def admin?
    role_admin?
  end

  def org_admin?
    org_admin
  end

  def can_manage_team?(team)
    admin? || org_admin? || team.owner_id == id || team_members.exists?(team: team, role: :manager)
  end

  def can_manage_organization?(organization)
    return false unless organization
    admin? || (org_admin? && self.organization_id == organization.id)
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

    update_column(:org_admin, true)
  end
end
