# frozen_string_literal: true

class CasePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user_can_access_case?
  end

  def background?
    user_can_access_case?
  end

  def timeline?
    user_can_access_case?
  end

  def events?
    user_can_access_case?
  end

  def create?
    user.instructor? || user.admin?
  end

  def edit?
    user_can_manage_case?
  end

  def update?
    user_can_manage_case?
  end

  def destroy?
    user_can_manage_case?
  end

  # Simulation management permissions
  def manage_simulation?
    user_can_manage_case?
  end

  def start_simulation?
    manage_simulation?
  end

  def pause_simulation?
    manage_simulation?
  end

  def resume_simulation?
    manage_simulation?
  end

  def complete_simulation?
    manage_simulation?
  end

  def trigger_arbitration?
    manage_simulation?
  end

  def advance_round?
    manage_simulation?
  end

  private

  def user_can_access_case?
    return true if user.admin?
    return true if user.instructor? && user_can_access_course?
    return true if record.created_by_id == user.id

    # Students can access cases if they're enrolled in the course and assigned to teams
    return false unless user_can_access_course?
    user.teams.joins(simulation: :case).exists?(simulations: {case_id: record.id})
  end

  def user_can_manage_case?
    return true if user.admin?
    return true if record.created_by_id == user.id
    return true if user.instructor? && user_can_access_course?

    false
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
      return scope.all if user.admin?

      if user.instructor?
        # Instructors can only access cases in courses they teach
        scope.joins(:course).where(course: {instructor: user})
      elsif user.student?
        # Students can only access cases where they are assigned to teams
        scope.joins(:teams).where(teams: {id: user.team_ids})
      else
        scope.none
      end
    end
  end
end
