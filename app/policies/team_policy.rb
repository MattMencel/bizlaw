# frozen_string_literal: true

class TeamPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user_can_access_team?
  end

  def create?
    user.instructor? || user.admin?
  end

  def update?
    user_can_manage_team?
  end

  def destroy?
    user_can_manage_team?
  end

  def join?
    return false unless user.student?
    return false if user.teams.include?(record)
    return false unless user_can_access_course?

    # Students can join teams if there's space and they're not already in it
    record.team_members.count < record.max_members
  end

  def leave?
    return false unless user.student?

    user.teams.include?(record)
  end

  private

  def user_can_access_team?
    return true if user.admin?
    return true if user.instructor? && user_can_access_course?
    return true if record.owner_id == user.id

    # Users can access teams they're members of if they're in the same course
    return false unless user_can_access_course?
    user.teams.include?(record)
  end

  def user_can_manage_team?
    return true if user.admin?
    return true if record.owner_id == user.id
    return true if user.instructor? && user_can_access_course?

    # Team managers can manage their teams if they're in the same course
    return false unless user_can_access_course?
    user.team_members.exists?(team: record, role: :manager)
  end

  def user_can_access_course?
    return true unless record.course
    return true if user.admin?
    return true if record.course.instructor == user
    
    # Students must be enrolled in the course
    record.course.enrolled?(user)
  end

  class Scope < Scope
    def resolve
      case user.role
      when "admin", "instructor"
        scope.all
      when "student"
        scope.joins(:team_members).where(team_members: { user_id: user.id })
      else
        scope.none
      end
    end
  end
end
