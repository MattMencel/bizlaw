# frozen_string_literal: true

class Invitation < ApplicationRecord
  include HasUuid

  # Associations
  belongs_to :invited_by, polymorphic: true
  belongs_to :organization, optional: true

  # Validations
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_blank: true
  validates :role, presence: true, inclusion: {in: %w[student instructor admin]}
  validates :token, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: {in: %w[pending accepted expired revoked]}
  validates :expires_at, presence: true
  validate :email_required_for_non_shareable
  validate :organization_required_for_non_admin_roles
  validate :no_duplicate_pending_invitations
  validate :role_permissions_valid

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :expired, -> { where(status: "expired") }
  scope :accepted, -> { where(status: "accepted") }
  scope :revoked, -> { where(status: "revoked") }
  scope :shareable, -> { where(shareable: true) }
  scope :email_based, -> { where(shareable: false) }
  scope :not_expired, -> { where("expires_at > ?", Time.current) }
  scope :for_organization, ->(org) { where(organization: org) }

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create
  before_save :check_expiration

  # Class methods
  def self.find_by_token(token)
    find_by(token: token)
  end

  def self.cleanup_expired
    where("expires_at < ? AND status = ?", Time.current, "pending")
      .update_all(status: "expired", updated_at: Time.current)
  end

  # Instance methods
  def expired?
    expires_at < Time.current
  end

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def revoked?
    status == "revoked"
  end

  def can_be_accepted?
    pending? && !expired?
  end

  def accept!(user = nil)
    return false unless can_be_accepted?

    transaction do
      if user
        # Update existing user
        user.update!(
          role: role,
          organization: organization,
          org_admin: org_admin?
        )
      else
        # Will be handled by registration flow
      end

      update!(
        status: "accepted",
        accepted_at: Time.current
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def revoke!
    return false unless pending?

    update(status: "revoked")
  end

  def resend!
    return false unless pending?

    update(
      token: generate_secure_token,
      expires_at: 7.days.from_now,
      updated_at: Time.current
    )
  end

  def invitation_url
    if shareable?
      Rails.application.routes.url_helpers.accept_shareable_invitation_url(token: token)
    else
      Rails.application.routes.url_helpers.accept_invitation_url(token: token)
    end
  end

  def share_urls
    return {} unless shareable?

    base_url = invitation_url
    encoded_url = CGI.escape(base_url)
    message = CGI.escape("Join #{organization&.name || "our platform"} as a #{role}")

    {
      facebook: "https://www.facebook.com/sharer/sharer.php?u=#{encoded_url}",
      twitter: "https://twitter.com/intent/tweet?url=#{encoded_url}&text=#{message}",
      linkedin: "https://www.linkedin.com/sharing/share-offsite/?url=#{encoded_url}"
    }
  end

  def org_admin?
    org_admin
  end

  private

  def generate_token
    self.token ||= generate_secure_token
  end

  def generate_secure_token
    SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 7.days.from_now
  end

  def check_expiration
    if pending? && expired?
      self.status = "expired"
    end
  end

  def email_required_for_non_shareable
    if !shareable? && email.blank?
      errors.add(:email, "is required for email-based invitations")
    end
  end

  def organization_required_for_non_admin_roles
    if role != "admin" && organization.nil?
      errors.add(:organization, "is required for non-admin roles")
    end
  end

  def no_duplicate_pending_invitations
    return unless email.present? && status == "pending"

    existing = self.class.where(email: email, status: "pending")
    existing = existing.where.not(id: id) if persisted?

    existing = if organization.present?
      existing.where(organization: organization)
    else
      existing.where(organization: nil)
    end

    if existing.exists?
      errors.add(:email, "already has a pending invitation")
    end
  end

  def role_permissions_valid
    return unless invited_by_type == "User" && invited_by.present?

    inviter = invited_by

    # Admin can invite to any role
    return if inviter.admin?

    # OrgAdmin can only invite within their organization
    if inviter.org_admin?
      unless organization == inviter.organization
        errors.add(:organization, "must match inviter organization for orgAdmin")
      end

      # OrgAdmin cannot invite to admin role
      if role == "admin"
        errors.add(:role, "cannot be admin when invited by orgAdmin")
      end
    else
      # Non-admin, non-orgAdmin users cannot invite
      errors.add(:invited_by, "does not have permission to send invitations")
    end
  end
end
