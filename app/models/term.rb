# frozen_string_literal: true

class Term < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :organization
  has_many :courses, dependent: :destroy

  # Validations
  validates :term_name, presence: true, length: { maximum: 100 }
  validates :academic_year, presence: true,
                           numericality: {
                             greater_than: 2000,
                             less_than_or_equal_to: -> { Date.current.year + 10 }
                           }
  validates :slug, presence: true,
                  length: { maximum: 50 },
                  uniqueness: { scope: :organization_id, case_sensitive: false },
                  format: { with: /\A[a-z0-9\-]+\z/, message: "must contain only lowercase letters, numbers, and hyphens" }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date
  validate :dates_within_academic_year

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && term_name.present? }
  before_validation :normalize_slug

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_year, ->(year) { where(academic_year: year) }
  scope :current, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :upcoming, -> { where("start_date > ?", Date.current) }
  scope :past, -> { where("end_date < ?", Date.current) }
  scope :by_start_date, -> { order(:start_date) }

  # Instance methods
  def display_name
    term_name
  end

  def full_name
    "#{term_name} (#{academic_year})"
  end

  def current?
    Date.current.between?(start_date, end_date)
  end

  def upcoming?
    start_date > Date.current
  end

  def past?
    end_date < Date.current
  end

  def duration_in_weeks
    ((end_date - start_date) / 7).ceil
  end

  def courses_count
    # Use counter cache column if available, fallback to SQL count
    read_attribute(:courses_count) || courses.count
  end

  def to_param
    slug
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def dates_within_academic_year
    return unless start_date && end_date && academic_year

    # Academic year typically spans from fall to spring (e.g., Fall 2024 to Spring 2025)
    year_start = Date.new(academic_year, 8, 1)      # August 1st of academic year
    year_end = Date.new(academic_year + 1, 8, 31)   # August 31st of following year

    if start_date < year_start || end_date > year_end
      errors.add(:base, "dates must fall within the academic year period (August #{academic_year} - August #{academic_year + 1})")
    end
  end

  def generate_slug
    base_slug = term_name.downcase
                         .gsub(/[^\w\s\-]/, "")     # Remove special characters
                         .gsub(/\s+/, "-")          # Replace spaces with hyphens
                         .gsub(/-+/, "-")           # Replace multiple hyphens with single
                         .strip
                         .gsub(/^-|-$/, "")         # Remove leading/trailing hyphens

    # Add academic year if not already included
    unless base_slug.include?(academic_year.to_s)
      base_slug = "#{base_slug}-#{academic_year}"
    end

    self.slug = base_slug
  end

  def normalize_slug
    return unless slug.present?

    self.slug = slug.downcase
                   .gsub(/[^\w\-]/, "")    # Remove invalid characters
                   .gsub(/-+/, "-")        # Replace multiple hyphens with single
                   .gsub(/^-|-$/, "")      # Remove leading/trailing hyphens
  end
end
