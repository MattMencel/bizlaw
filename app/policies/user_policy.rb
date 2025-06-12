# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    user.instructor? || user.admin?
  end

  def show?
    user.admin? || user.instructor? || user == record
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || user == record
  end

  def destroy?
    user.admin? && user != record
  end

  def impersonate?
    user.admin? && user != record && record.present?
  end

  def stop_impersonation?
    user.admin?
  end

  def enable_full_permissions?
    user.admin?
  end

  def disable_full_permissions?
    user.admin?
  end

  def assign_org_admin?
    return false unless user.organization == record.organization
    user.admin? || user.can_assign_org_admin?
  end

  def remove_org_admin?
    return false unless user.organization == record.organization
    user.admin? || (user.can_assign_org_admin? && user != record)
  end

  class Scope < Scope
    def resolve
      case user.role
      when "admin"
        scope.all
      when "instructor"
        scope.all
      when "student"
        # Students can only see themselves and their teammates
        teammate_ids = user.teams.joins(:team_members).pluck("team_members.user_id")
        scope.where(id: [ user.id ] + teammate_ids)
      else
        scope.none
      end
    end
  end
end
