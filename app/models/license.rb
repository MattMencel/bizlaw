# frozen_string_literal: true

class License < ApplicationRecord
  include HasUuid
  include SoftDeletable

  # Associations
  has_one :organization, dependent: :nullify
  has_many :users, through: :organization

  # Validations
  validates :license_key, presence: true, uniqueness: true
  validates :organization_name, presence: true
  validates :contact_email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :license_type, presence: true
  validates :signature, presence: true
  validates :max_instructors, :max_students, :max_courses,
    presence: true, numericality: {greater_than: 0}

  # Enums
  enum :license_type, {
    free: "free",
    starter: "starter",
    professional: "professional",
    enterprise: "enterprise"
  }, prefix: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :expired, -> { where("expires_at < ?", Date.current) }
  scope :expiring_soon, -> { where(expires_at: Date.current..30.days.from_now) }

  # Callbacks
  before_validation :generate_license_key, if: -> { license_key.blank? }
  before_save :update_validation_hash
  after_create :create_default_organization

  # Class methods
  def self.default_free_license
    find_or_create_by(license_type: "free", organization_name: "Default") do |license|
      license.contact_email = "admin@example.com"
      license.license_key = "FREE-LICENSE-DEFAULT"
      license.max_instructors = 10
      license.max_students = 100
      license.max_courses = 20
      license.active = true
      license.features = {}
      license.signature = sign_license_data(license.attributes_for_signing)
    end
  end

  def self.validate_license_key(key)
    license = find_by(license_key: key, active: true)
    return nil unless license
    return nil if license.expired?

    if license.valid_signature?
      license.touch(:last_validated_at)
      license
    end
  end

  def self.generate_signed_license(attrs)
    permitted_attrs = attrs.slice(
      :organization_name, :contact_email, :license_type,
      :max_instructors, :max_students, :max_courses,
      :expires_at, :notes, :features, :active
    )
    license = new
    permitted_attrs.each { |key, value| license.send("#{key}=", value) }
    license.signature = sign_license_data(license.attributes_for_signing)
    license
  end

  # Instance methods
  def expired?
    expires_at.present? && expires_at < Date.current
  end

  def expiring_soon?
    expires_at.present? && expires_at <= 30.days.from_now
  end

  def days_until_expiry
    return nil unless expires_at
    (expires_at - Date.current).to_i
  end

  def valid_signature?
    return false if signature.blank?

    begin
      expected_signature = self.class.sign_license_data(attributes_for_signing)
      ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
    rescue => e
      Rails.logger.warn "License signature validation failed: #{e.message}"
      false
    end
  end

  def attributes_for_signing
    {
      license_key: license_key,
      organization_name: organization_name,
      contact_email: contact_email,
      license_type: license_type,
      max_instructors: max_instructors,
      max_students: max_students,
      max_courses: max_courses,
      expires_at: expires_at&.iso8601,
      features: features.to_json
    }
  end

  def usage_stats
    return {} unless organization

    {
      instructors_count: organization.users.where(role: "instructor").count,
      students_count: organization.users.where(role: "student").count,
      courses_count: organization.users.joins(:taught_courses).distinct.count,
      instructors_limit: max_instructors,
      students_limit: max_students,
      courses_limit: max_courses
    }
  end

  def within_limits?
    stats = usage_stats
    return true if stats.empty?

    stats[:instructors_count] <= max_instructors &&
      stats[:students_count] <= max_students &&
      stats[:courses_count] <= max_courses
  end

  def can_add_user?(role)
    return true unless organization

    stats = usage_stats
    case role.to_s
    when "instructor"
      stats[:instructors_count] < max_instructors
    when "student"
      stats[:students_count] < max_students
    else
      true
    end
  end

  def can_add_course?
    return true unless organization

    stats = usage_stats
    stats[:courses_count] < max_courses
  end

  def display_name
    "#{organization_name} (#{license_type.titleize})"
  end

  def feature_enabled?(feature_name)
    return true if license_type_enterprise?

    case feature_name.to_s
    when "advanced_analytics"
      license_type_professional? || license_type_enterprise?
    when "custom_branding"
      license_type_professional? || license_type_enterprise?
    when "api_access"
      license_type_starter? || license_type_professional? || license_type_enterprise?
    when "priority_support"
      license_type_professional? || license_type_enterprise?
    else
      features[feature_name.to_s] == true
    end
  end

  private

  def generate_license_key
    type = license_type&.upcase || "FREE"
    loop do
      key = "#{type}-#{SecureRandom.hex(4).upcase}-#{SecureRandom.hex(4).upcase}"
      break self.license_key = key unless License.exists?(license_key: key)
    end
  end

  def update_validation_hash
    self.validation_hash = Digest::SHA256.hexdigest([
      license_key, organization_name, license_type,
      max_instructors, max_students, max_courses
    ].join("|"))
  end

  def create_default_organization
    return if organization.present?

    Organization.create!(
      name: organization_name,
      license: self,
      slug: organization_name.parameterize,
      domain: "#{organization_name.parameterize}.example.edu",
      active: true
    )
  end

  # Cryptographic signing
  def self.sign_license_data(data)
    # Use a combination of HMAC and timestamp for reasonable security
    # In production, you'd want to use RSA or ECDSA with a private key
    secret_key = Rails.application.credentials.license_signing_key ||
      Rails.application.secret_key_base

    timestamp = Time.current.to_i
    payload = "#{data.to_json}|#{timestamp}"

    signature = OpenSSL::HMAC.hexdigest("SHA256", secret_key, payload)
    Base64.strict_encode64("#{signature}|#{timestamp}")
  end

  private_class_method :sign_license_data
end
