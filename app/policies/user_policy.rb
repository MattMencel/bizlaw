# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    user.instructor? || user.admin? || user.org_admin?
  end

  def show?
    return true if user.admin? || user == record

    if user.org_admin? && !user.admin?
      return false unless user.organization_id && record.organization_id
      return user.organization_id == record.organization_id
    end

    user.instructor?
  end

  def create?
    user.admin?
  end

  def update?
    return true if user.admin? || user == record

    if user.org_admin? && !user.admin?
      return false unless user.organization_id && record.organization_id
      return user.organization_id == record.organization_id
    end

    false
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
      # Check if user has any valid roles
      return scope.none if user.roles.blank?

      # Org admins are restricted to their organization users only (unless they're also regular admins)
      if user.org_admin? && !user.admin?
        return scope.none unless user.organization_id
        scope.where(organization_id: user.organization_id)
      else
        case user.role
        when "admin"
          scope.all
        when "instructor"
          scope.all
        when "student"
          # Students can only see themselves and their teammates
          teammate_ids = user.teams.joins(:team_members).pluck("team_members.user_id")
          all_ids = ([user.id] + teammate_ids).uniq
          scope.where(id: all_ids)
        else
          scope.none
        end
      end
    end
  end
end
