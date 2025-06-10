# frozen_string_literal: true

class Team < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :owner, class_name: "User"
  belongs_to :course, optional: true
  has_many :team_members, dependent: :destroy
  has_many :users, through: :team_members
  has_many :members, through: :team_members, source: :user
  has_many :case_teams, dependent: :destroy
  has_many :cases, through: :case_teams
  has_many :documents, as: :documentable, dependent: :destroy

  # Validations
  validates :name, presence: true,
                  length: { maximum: 255 },
                  uniqueness: { scope: :owner_id, case_sensitive: false }
  validates :description, presence: true
  validates :owner_id, presence: true
  validates :max_members, presence: true, numericality: { greater_than: 0 }
  validate :validate_member_limit, on: :create

  # Scopes
  scope :by_owner, ->(user) { where(owner: user) }
  scope :search_by_name, ->(query) {
    where("LOWER(name) LIKE :query", query: "%#{query.downcase}%")
  }
  scope :with_member, ->(user) {
    joins(:team_members).where(team_members: { user_id: user.id })
  }
  scope :with_role, ->(role) {
    joins(:team_members).where(team_members: { role: role })
  }
  scope :accessible_by, ->(user) {
    case user.role
    when "admin", "instructor"
      all
    when "student"
      joins(:team_members).where(team_members: { user_id: user.id })
    else
      none
    end
  }

  # Instance methods
  def display_name
    name
  end

  def member?(user)
    team_members.exists?(user: user)
  end

  def manager?(user)
    team_members.exists?(user: user, role: :manager) || owner_id == user.id
  end

  def add_member(user, role: :member)
    return false if member?(user)
    return false if team_members.count >= max_members

    team_members.create(user: user, role: role)
  end

  def remove_member(user)
    return false if owner_id == user.id

    team_members.find_by(user: user)&.destroy
  end

  def change_member_role(user, new_role)
    return false unless member?(user)
    return false if owner_id == user.id

    team_members.find_by(user: user)&.update(role: new_role)
  end

  def member_count
    team_members.count
  end

  def full?
    member_count >= max_members
  end

  private

  # Callbacks
  before_validation :normalize_name

  def normalize_name
    self.name = name.strip if name.present?
  end

  def validate_member_limit
    return unless team_members.size > max_members

    errors.add(:base, "Team has reached maximum member limit")
  end
end
