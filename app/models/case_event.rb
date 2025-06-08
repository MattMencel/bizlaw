# frozen_string_literal: true

class CaseEvent < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  belongs_to :case
  belongs_to :user

  enum :event_type, {
    created: "created",
    updated: "updated",
    status_changed: "status_changed",
    document_added: "document_added",
    document_removed: "document_removed",
    team_member_added: "team_member_added",
    team_member_removed: "team_member_removed",
    comment_added: "comment_added"
  }, prefix: true

  validates :event_type, presence: true
  validates :data, presence: true
  validate :validate_data_format

  before_validation :set_default_data

  private

  def validate_data_format
    return if data.is_a?(Hash)

    errors.add(:data, "must be a valid JSON object")
  end

  def set_default_data
    self.data ||= {}
  end
end
