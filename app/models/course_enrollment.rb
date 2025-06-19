# frozen_string_literal: true

class CourseEnrollment < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :user
  belongs_to :course

  # Validations
  validates :user_id, presence: true
  validates :course_id, presence: true
  validates :status, presence: true, inclusion: {in: %w[active inactive withdrawn]}
  validates :enrolled_at, presence: true
  validates :user_id, uniqueness: {scope: :course_id, message: "is already enrolled in this course"}
  validate :user_must_be_student

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :withdrawn, -> { where(status: "withdrawn") }
  scope :for_course, ->(course) { where(course: course) }
  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(enrolled_at: :desc) }

  # Callbacks
  before_validation :set_enrolled_at, on: :create

  # Instance methods
  def active?
    status == "active"
  end

  def can_access_course?
    active? && course.active?
  end

  def withdraw!
    update!(status: "withdrawn")
  end

  def reactivate!
    update!(status: "active")
  end

  def deactivate!
    update!(status: "inactive")
  end

  def enrollment_duration
    return nil unless enrolled_at

    end_time = case status
    when "withdrawn"
      updated_at
    when "inactive"
      updated_at
    else
      Time.current
    end

    end_time - enrolled_at
  end

  private

  def set_enrolled_at
    self.enrolled_at ||= Time.current
  end

  def user_must_be_student
    return unless user

    unless user.student?
      errors.add(:user, "must be a student to enroll in courses")
    end
  end
end
