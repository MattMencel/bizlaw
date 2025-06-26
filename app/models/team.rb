# frozen_string_literal: true

class Team < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable

  # Associations
  belongs_to :owner, class_name: "User"
  belongs_to :simulation
  has_many :team_members, dependent: :destroy
  has_many :users, through: :team_members
  has_many :members, through: :team_members, source: :user
  has_many :documents, as: :documentable, dependent: :destroy

  # Delegated associations
  delegate :case, to: :simulation
  delegate :course, to: :case

  # Validations
  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :name, presence: true,
    length: {maximum: 255},
    uniqueness: {scope: [:simulation_id, :owner_id], case_sensitive: false}
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  validates :description, presence: true
  validates :max_members, presence: true, numericality: {greater_than: 0}
  validates :role, presence: true
  validate :validate_member_limit, on: :create
  validate :owner_must_be_enrolled_in_course

  # Enums
  enum :role, {
    plaintiff: "plaintiff",
    defendant: "defendant"
  }, prefix: :role

  # Scopes
  scope :by_owner, ->(user) { where(owner: user) }
  scope :search_by_name, ->(query) {
    where("LOWER(name) LIKE :query", query: "%#{query.downcase}%")
  }
  scope :with_member, ->(user) {
    joins(:team_members).where(team_members: {user_id: user.id})
  }
  scope :with_member_role, ->(role) {
    joins(:team_members).where(team_members: {role: role})
  }
  scope :with_case_role, ->(role) {
    where(role: role)
  }
  scope :accessible_by, ->(user) {
    case user.role
    when "admin", "instructor"
      all
    when "student"
      joins(:team_members).where(team_members: {user_id: user.id})
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
    return false unless user_enrolled_in_course?(user)

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
    team_members_count
  end

  def full?
    member_count >= max_members
  end

  def case_role
    role || "unassigned"
  end

  def role_in_case(case_obj)
    (case_obj == self.case) ? role : nil
  end

  def primary_case
    self.case
  end

  def has_student_members?
    users.students.exists?
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

  def owner_must_be_enrolled_in_course
    return unless owner && simulation&.case&.course

    unless simulation.case.course.enrolled?(owner)
      errors.add(:owner, "must be enrolled in the course")
    end
  end

  def user_enrolled_in_course?(user)
    simulation&.case&.course&.enrolled?(user)
  end
end
