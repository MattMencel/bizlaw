# frozen_string_literal: true

class TeamMember < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :team, counter_cache: true
  belongs_to :user
  has_many :documents, as: :documentable, dependent: :destroy

  # Validations
  validates :role, presence: true
  validates :user_id, uniqueness: {
    scope: :team_id,
    message: "is already a member of this team"
  }
  validate :team_not_full, on: :create
  validate :not_owner_role_change, on: :update, if: :role_changed?

  # Enums
  enum :role, {
    member: "member",
    manager: "manager"
  }, prefix: :role

  # Scopes
  scope :managers, -> { where(role: :manager) }
  scope :members, -> { where(role: :member) }
  scope :by_role, ->(role) { where(role: role) }
  scope :active_in_team, ->(team) { where(team: team).where(deleted_at: nil) }
  scope :for_user, ->(user) { where(user: user) }

  # Instance methods
  def manager?
    role_manager?
  end

  def display_name
    "#{user.full_name} (#{role})"
  end

  private

  def team_not_full
    if team&.full? && team.team_members.where.not(id: id).exists?
      errors.add(:base, "Team has reached maximum member capacity")
    end
  end

  def not_owner_role_change
    if user_id == team.owner_id
      errors.add(:role, "cannot be changed for team owner")
    end
  end
end
