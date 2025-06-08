# frozen_string_literal: true

class CasePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user_can_access_case?
  end

  def create?
    user.instructor? || user.admin?
  end

  def update?
    user_can_manage_case?
  end

  def destroy?
    user_can_manage_case?
  end

  private

  def user_can_access_case?
    return true if user.admin?
    return true if user.instructor?
    return true if record.created_by_id == user.id

    # Students can access cases their teams are assigned to
    user.teams.joins(:case_teams).exists?(case_teams: { case_id: record.id })
  end

  def user_can_manage_case?
    return true if user.admin?
    return true if record.created_by_id == user.id
    return true if user.instructor?

    false
  end

  class Scope < Scope
    def resolve
      case user.role
      when "admin"
        scope.all
      when "instructor"
        scope.all
      when "student"
        scope.joins(:assigned_teams).where(teams: { id: user.team_ids })
      else
        scope.none
      end
    end
  end
end
