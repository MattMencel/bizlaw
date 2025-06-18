# frozen_string_literal: true

require "rqrcode"
require "chunky_png"
require "base64"

class CourseInvitation < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :course

  # Validations
  validates :token, presence: true, uniqueness: true
  validates :course_id, presence: true
  validates :current_uses, presence: true,
                          numericality: { greater_than_or_equal_to: 0 }
  validates :max_uses, numericality: { greater_than: 0 }, allow_nil: true
  validate :max_uses_not_exceeded
  validate :not_expired

  # Scopes
  scope :active, -> { where(active: true) }
  scope :valid_invitations, -> {
    active.where(
      "expires_at IS NULL OR expires_at > ? AND (max_uses IS NULL OR current_uses < max_uses)",
      Time.current
    )
  }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :usage_exceeded, -> { where("max_uses IS NOT NULL AND current_uses >= max_uses") }

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_defaults, on: :create

  # Class methods
  def self.find_valid_invitation(token)
    valid_invitations.find_by(token: token)
  end

  def self.generate_unique_token
    loop do
      token = SecureRandom.alphanumeric(8).upcase
      break token unless exists?(token: token)
    end
  end

  # Instance methods
  def invitation_valid?
    return false unless active?
    return false if expired?
    return false if usage_exceeded?
    true
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def usage_exceeded?
    max_uses.present? && current_uses >= max_uses
  end

  def remaining_uses
    return Float::INFINITY if max_uses.nil?
    [ max_uses - current_uses, 0 ].max
  end

  def can_be_used?
    active? && !expired? && !usage_exceeded?
  end

  def use!
    return false unless can_be_used?

    increment!(:current_uses)

    # Auto-deactivate if max uses reached
    if usage_exceeded?
      update!(active: false)
    end

    true
  end

  def expire!
    update!(expires_at: Time.current, active: false)
  end

  def extend_expiration(duration)
    new_expiration = if expires_at.present?
      [ expires_at + duration, Time.current + duration ].max
    else
      Time.current + duration
    end

    update!(expires_at: new_expiration, active: true)
  end

  def invitation_url
    host = Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
    Rails.application.routes.url_helpers.course_invitation_url(token, host: host)
  end

  def qr_code_svg(size: 200)
    return @qr_code_svg if @qr_code_svg && @qr_code_size == size

    @qr_code_size = size
    @qr_code_svg = generate_qr_code_svg(size)
  end

  def qr_code_png(size: 200, fill: "000000", background: "FFFFFF")
    qrcode = RQRCode::QRCode.new(invitation_url)
    qrcode.as_png(
      resize_gte_to: false,
      resize_exactly_to: size,
      fill: ChunkyPNG::Color(background),
      color: ChunkyPNG::Color(fill),
      size: size,
      border_modules: 4,
      module_px_size: 4
    )
  end

  def qr_code_data_uri(size: 200, fill: "000000", background: "FFFFFF")
    png_data = qr_code_png(size: size, fill: fill, background: background)
    "data:image/png;base64,#{Base64.strict_encode64(png_data.to_s)}"
  end

  def status
    return "expired" if expired?
    return "usage_exceeded" if usage_exceeded?
    return "inactive" unless active?
    "active"
  end

  def display_name
    name.presence || "Invitation #{token}"
  end

  def usage_summary
    if max_uses.present?
      "#{current_uses}/#{max_uses} uses"
    else
      "#{current_uses} uses"
    end
  end

  private

  def generate_token
    self.token ||= self.class.generate_unique_token
  end

  def generate_qr_code_svg(size)
    qrcode = RQRCode::QRCode.new(invitation_url)
    qrcode.as_svg(
      offset: 0,
      color: "#000000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true,
      use_path: true,
      viewbox: true,
      svg_attributes: {
        width: size,
        height: size,
        class: "qr-code",
        style: "background-color: white;"
      }
    )
  end

  def set_defaults
    self.current_uses ||= 0
    self.active = true if active.nil?
  end

  def max_uses_not_exceeded
    return unless max_uses.present? && current_uses.present?

    if current_uses > max_uses
      errors.add(:current_uses, "cannot exceed maximum uses")
    end
  end

  def not_expired
    return unless expires_at.present?

    if expires_at <= Time.current
      errors.add(:expires_at, "cannot be in the past")
    end
  end
end
