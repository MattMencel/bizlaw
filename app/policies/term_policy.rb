# frozen_string_literal: true

class TermPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && (user.admin? || user.can_manage_organization?(record.organization) ||
                      user.organization == record.organization)
  end

  def create?
    user.admin? || user.can_manage_organization?(record&.organization)
  end

  def update?
    user.admin? || user.can_manage_organization?(record.organization)
  end

  def destroy?
    user.admin? || user.can_manage_organization?(record.organization)
  end

  class Scope < Scope
    def resolve
      case user.role
      when "admin"
        scope.all
      when "instructor"
        if user.org_admin?
        end
        scope.where(organization: user.organization)
      when "student"
        scope.where(organization: user.organization)
      else
        scope.none
      end
    end
  end
end
