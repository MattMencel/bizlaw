module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { unscoped.where.not(deleted_at: nil) }
    default_scope { where(deleted_at: nil) }
  end

  def soft_delete
    return if deleted?
    attrs = {deleted_at: Time.current}
    attrs[:active] = false if has_attribute?(:active)
    update(attrs)
  end

  def restore
    attrs = {deleted_at: nil}
    attrs[:active] = true if has_attribute?(:active)
    update(attrs)
  end

  def deleted?
    deleted_at.present?
  end

  def active?
    !deleted?
  end
end
