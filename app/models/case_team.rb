# frozen_string_literal: true

class CaseTeam < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  belongs_to :case
  belongs_to :team

  enum :role, { plaintiff: "plaintiff", defendant: "defendant" }, prefix: :role

  validates :role, presence: true
  validates :case_id, uniqueness: { scope: :role, message: "should have only one team per role" }
  validates :case_id, uniqueness: { scope: :team_id, message: "team already assigned to this case" }
end
