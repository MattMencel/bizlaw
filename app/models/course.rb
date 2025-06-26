# frozen_string_literal: true

class Course < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :organization, counter_cache: true
  belongs_to :instructor, class_name: "User"
  belongs_to :term, optional: true, counter_cache: true
  has_many :course_enrollments, dependent: :destroy
  has_many :students, through: :course_enrollments, source: :user
  has_many :course_invitations, dependent: :destroy
  has_many :cases, dependent: :destroy
  has_many :simulations, through: :cases
  has_many :teams, through: :simulations

  # Validations
  validates :title, presence: true, length: {maximum: 255}
  validates :course_code, presence: true,
    length: {maximum: 20},
    uniqueness: {scope: :organization_id, case_sensitive: false}
  validates :year, presence: true,
    numericality: {
      greater_than: 2000,
      less_than_or_equal_to: -> { Date.current.year + 5 }
    }
  validate :instructor_must_be_instructor_or_admin
  validate :end_date_after_start_date

  # Callbacks
  before_create :enforce_license_limits

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_instructor, ->(user) { where(instructor: user) }
  scope :current_semester, -> {
    # Courses with terms that are currently active
    term_courses = joins(:term).where(terms: {start_date: ..Date.current, end_date: Date.current..})

    # Legacy courses without terms - fall back to year
    legacy_courses = where(term_id: nil, year: Date.current.year)

    # Combine both
    from("(#{term_courses.to_sql} UNION #{legacy_courses.to_sql}) AS courses")
  }
  scope :for_term, ->(term) { where(term: term) }
  scope :for_academic_year, ->(year) {
    # Courses with terms for the given academic year
    term_courses = joins(:term).where(terms: {academic_year: year})

    # Legacy courses without terms
    legacy_courses = where(term_id: nil, year: year)

    # Combine both
    from("(#{term_courses.to_sql} UNION #{legacy_courses.to_sql}) AS courses")
  }
  scope :search_by_title, ->(query) {
    where("LOWER(title) LIKE :query", query: "%#{query.downcase}%")
  }
  scope :search_by_code, ->(query) {
    where("LOWER(course_code) LIKE :query", query: "%#{query.downcase}%")
  }

  # Instance methods
  def display_name
    "#{course_code}: #{title}"
  end

  def semester_display
    return term.term_name if term.present?
    return semester if semester.present?

    # Fallback for courses without terms
    case Date.current.month
    when 1..5
      "Spring"
    when 6..8
      "Summer"
    when 9..12
      "Fall"
    end
  end

  def academic_year
    return term.academic_year if term.present?
    year # Fallback to old year field
  end

  def full_title
    "#{display_name} (#{semester_display} #{academic_year})"
  end

  def term_name
    term&.term_name || semester_display
  end

  def enrolled?(user)
    # Students must be enrolled through course_enrollments
    return course_enrollments.exists?(user: user, status: "active") if user.student?

    # Instructors and admins are considered "enrolled" if they can manage the course
    return true if can_be_managed_by?(user)

    false
  end

  def enroll_student(user, invitation = nil)
    return false if enrolled?(user)
    return false unless user.student?

    enrollment = course_enrollments.create(
      user: user,
      enrolled_at: Time.current,
      status: "active"
    )

    # Track invitation usage if provided
    if invitation && enrollment.persisted?
      invitation.increment!(:current_uses)
    end

    enrollment.persisted?
  end

  def student_count
    course_enrollments.where(status: "active").count
  end

  def can_be_managed_by?(user)
    return true if user.admin?
    return true if instructor == user
    false
  end

  # Direct assignment methods
  def direct_assignment_enabled?
    organization.direct_assignment_enabled?
  end

  def available_students_for_assignment
    return User.none unless direct_assignment_enabled?

    # Get all students in the organization who are not already enrolled
    organization.students
      .active
      .where.not(id: students.select(:id))
      .order(:last_name, :first_name)
  end

  def assign_student_directly!(user)
    return false unless direct_assignment_enabled?
    return false unless user.student?
    return false unless organization.user_belongs_to_organization?(user)
    return false if enrolled?(user)

    enroll_student(user)
  end

  def remove_student_directly!(user)
    return false unless direct_assignment_enabled?
    return false unless user.student?
    return false unless enrolled?(user)

    # Find and withdraw the enrollment
    enrollment = course_enrollments.find_by(user: user, status: "active")
    return false unless enrollment

    enrollment.withdraw!
  end

  def can_assign_students_directly?(current_user)
    direct_assignment_enabled? && can_be_managed_by?(current_user)
  end

  private

  def instructor_must_be_instructor_or_admin
    return unless instructor

    unless instructor.instructor? || instructor.admin?
      errors.add(:instructor, "must be an instructor or admin")
    end
  end

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def enforce_license_limits
    return if Rails.application.config.skip_license_enforcement
    return unless organization

    enforcement_service = LicenseEnforcementService.new(organization: organization)

    begin
      enforcement_service.enforce_course_limit!
    rescue LicenseEnforcementService::LicenseLimitExceeded => e
      errors.add(:base, e.message)
      throw :abort
    end
  end
end
