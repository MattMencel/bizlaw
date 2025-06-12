# frozen_string_literal: true

class Organization < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :license, optional: true
  has_many :users, dependent: :nullify
  has_many :terms, dependent: :destroy
  has_many :courses, dependent: :destroy
  has_many :instructors, -> { where(role: :instructor) }, class_name: "User"
  has_many :students, -> { where(role: :student) }, class_name: "User"
  has_many :admins, -> { where(role: :admin) }, class_name: "User"
  has_many :org_admins, -> { where(org_admin: true) }, class_name: "User"

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :domain, presence: true,
                    length: { maximum: 100 },
                    uniqueness: { case_sensitive: false },
                    format: {
                      with: /\A[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/,
                      message: "must be a valid domain (e.g., university.edu)"
                    }
  validates :slug, presence: true,
                  length: { maximum: 50 },
                  uniqueness: { case_sensitive: false },
                  format: {
                    with: /\A[a-z0-9-]+\z/,
                    message: "must contain only lowercase letters, numbers, and hyphens"
                  }

  # Callbacks
  before_validation :normalize_slug
  before_validation :normalize_domain
  after_create :assign_default_license, unless: :license

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_domain, ->(domain) { where(domain: domain.downcase) }
  scope :search_by_name, ->(query) {
    where("LOWER(name) LIKE :query", query: "%#{query.downcase}%")
  }

  # Class methods
  def self.find_by_email_domain(email)
    domain = email.split("@").last&.downcase
    return nil unless domain

    find_by(domain: domain, active: true)
  end

  def self.generate_slug_from_name(name)
    name.downcase
        .gsub(/[^a-z0-9\s-]/, "")  # Remove special chars
        .gsub(/\s+/, "-")          # Replace spaces with hyphens
        .gsub(/-+/, "-")           # Collapse multiple hyphens
        .gsub(/^-|-$/, "")         # Remove leading/trailing hyphens
  end

  # Instance methods
  def display_name
    name
  end

  def branded_url(path = "")
    "#{slug}.bizlaw.edu#{path}"
  end

  def course_count
    courses.active.count
  end

  def student_count
    students.count
  end

  def instructor_count
    instructors.count
  end

  def user_belongs_to_organization?(user)
    return false unless user&.email

    email_domain = user.email.split("@").last&.downcase
    email_domain == domain
  end

  def auto_assign_user?(user)
    user_belongs_to_organization?(user) && active?
  end

  def full_domain_name
    "#{slug}.bizlaw.edu"
  end

  # License-related methods
  def effective_license
    license || License.default_free_license
  end

  def within_license_limits?
    effective_license.within_limits?
  end

  def can_add_user?(role)
    effective_license.can_add_user?(role)
  end

  def can_add_course?
    effective_license.can_add_course?
  end

  def license_status
    return "unlicensed" unless license
    return "expired" if license.expired?
    return "expiring_soon" if license.expiring_soon?
    return "over_limits" unless within_license_limits?

    "valid"
  end

  def usage_summary
    {
      instructors: { count: instructor_count, limit: effective_license.max_instructors },
      students: { count: student_count, limit: effective_license.max_students },
      courses: { count: course_count, limit: effective_license.max_courses }
    }
  end

  def feature_enabled?(feature_name)
    effective_license.feature_enabled?(feature_name)
  end

  def license_warnings
    warnings = []

    if license&.expired?
      warnings << "License expired on #{license.expires_at}"
    elsif license&.expiring_soon?
      warnings << "License expires in #{license.days_until_expiry} days"
    end

    unless within_license_limits?
      usage = usage_summary
      usage.each do |type, data|
        if data[:count] > data[:limit]
          warnings << "#{type.to_s.humanize} count (#{data[:count]}) exceeds limit (#{data[:limit]})"
        end
      end
    end

    warnings
  end

  private

  def normalize_slug
    return unless name.present?

    self.slug = self.class.generate_slug_from_name(name) if slug.blank?
    self.slug = slug.downcase.strip
  end

  def normalize_domain
    self.domain = domain.downcase.strip if domain.present?
  end

  def assign_default_license
    return if Rails.application.config.skip_license_enforcement
    self.update!(license: License.default_free_license)
  end
end
