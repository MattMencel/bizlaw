# frozen_string_literal: true

class SimulationPolicy < ApplicationPolicy
  def show?
    # Users can view simulation if they're assigned to the case
    user_assigned_to_case? || admin_or_instructor?
  end

  def participate?
    # Users can participate if they're on a team assigned to the case
    user_on_assigned_team? && simulation_active?
  end

  def manage?
    # Only admins and instructors can manage simulations
    admin_or_instructor?
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  private

  def user_assigned_to_case?
    return false unless record&.case

    case user.role
    when "admin", "instructor"
      true
    when "student"
      user.teams.joins(:case_teams).where(case_teams: { case: record.case }).exists?
    else
      false
    end
  end

  def user_on_assigned_team?
    return false unless record&.case

    user_teams = user.teams.joins(:case_teams).where(case_teams: { case: record.case })
    assigned_teams = [ record.plaintiff_team, record.defendant_team ].compact

    (user_teams & assigned_teams).any?
  end

  def simulation_active?
    record&.active?
  end

  def admin_or_instructor?
    user.admin? || user.instructor?
  end
end
