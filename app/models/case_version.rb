# frozen_string_literal: true

# What a Simulation pins. A published Version never changes again, so a grading
# dispute reopened months later reaches the material the Simulation ran on. A
# draft is the professor's working copy and no Simulation may pin it.
#
# Published-ness is derived from `published_at`; there is no status column.
class CaseVersion < ApplicationRecord
  retention :authored

  belongs_to :case, inverse_of: :versions
  has_many :calendar_days,
    -> { order(:ordinal) },
    class_name: "CaseCalendarDay",
    inverse_of: :case_version,
    dependent: :destroy

  validates :version, presence: true, uniqueness: {scope: :case_id}

  def published? = published_at.present?

  def draft? = !published?

  # The Day count is the length of the authored calendar rather than a column
  # beside it, so the two can never disagree.
  def day_count = calendar_days.size
end
