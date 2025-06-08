# frozen_string_literal: true

module HasTimestamps
  extend ActiveSupport::Concern

  included do
    # Ensure standard Rails timestamps are present
    validates :created_at, presence: true
    validates :updated_at, presence: true

    before_create :set_creation_time
    before_save :set_update_time

    # Scopes for timestamp-based queries
    scope :created_before, ->(time) { where(arel_table[:created_at].lt(time)) }
    scope :created_after, ->(time) { where(arel_table[:created_at].gt(time)) }
    scope :updated_before, ->(time) { where(arel_table[:updated_at].lt(time)) }
    scope :updated_after, ->(time) { where(arel_table[:updated_at].gt(time)) }
    scope :created_between, ->(start_time, end_time) {
      where(created_at: start_time..end_time)
    }
    scope :updated_between, ->(start_time, end_time) {
      where(updated_at: start_time..end_time)
    }
    scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }
    scope :recently_updated, ->(limit = 10) { order(updated_at: :desc).limit(limit) }
  end

  # Instance methods for timestamp manipulation
  def touch_with_version
    touch
    increment_version if respond_to?(:increment_version)
  end

  def created_ago
    time_ago_in_words(created_at)
  end

  def updated_ago
    time_ago_in_words(updated_at)
  end

  private

  def set_creation_time
    self.created_at ||= current_time_from_proper_timezone
  end

  def set_update_time
    self.updated_at = current_time_from_proper_timezone
  end

  def time_ago_in_words(time)
    return "" unless time
    ActionView::Helpers::DateHelper.time_ago_in_words(time)
  end
end
