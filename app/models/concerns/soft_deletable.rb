module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
  end

  def soft_delete
    update(active: false)
  end

  def restore
    update(active: true)
  end

  def deleted?
    !active?
  end
end
