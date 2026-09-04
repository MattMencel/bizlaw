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
  # The Action menu, cheapest first, which is the order an Action Board reads in.
  has_many :actions,
    -> { order(:cost, :kind) },
    class_name: "CaseAction",
    inverse_of: :case_version,
    dependent: :destroy
  # One Client for each Side's role. An Exhibit targets one of them.
  has_many :clients, class_name: "CaseClient", inverse_of: :case_version, dependent: :destroy
  # The Terms vocabulary an Offer is built from and an Exhibit bears on.
  has_many :terms, class_name: "CaseTerm", inverse_of: :case_version, dependent: :destroy
  # Everything a Team could come to hold, each waiting behind the Action that
  # discovers it.
  has_many :documents, class_name: "CaseDocument", inverse_of: :case_version, dependent: :destroy

  validates :version, presence: true, uniqueness: {scope: :case_id}

  def published? = published_at.present?

  def draft? = !published?

  # The Day count is the length of the authored calendar rather than a column
  # beside it, so the two can never disagree.
  def day_count = calendar_days.size
end
