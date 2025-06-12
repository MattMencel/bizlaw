module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { unscoped.where.not(deleted_at: nil) }
    default_scope { where(deleted_at: nil) }
  end

  def soft_delete
    return if deleted?
    update(deleted_at: Time.current, active: false)
  end

  def restore
    update(deleted_at: nil, active: true)
  end

  def deleted?
    deleted_at.present?
  end

  def active?
    !deleted?
  end
end
