# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  def index?
    user&.admin? == true
  end

  def show?
    user&.admin? == true || user&.can_manage_organization?(record)
  end

  def create?
    user&.admin? == true
  end

  def update?
    user&.admin? == true || user&.can_manage_organization?(record)
  end

  def destroy?
    user&.admin? == true && record.users.empty?
  end

  def activate?
    user&.admin? == true
  end

  def deactivate?
    user&.admin? == true
  end

  def manage_org_admins?
    user&.admin? == true || user&.can_manage_organization?(record)
  end

  def assign_org_admin?
    user&.admin? == true || user&.can_manage_organization?(record)
  end

  def manage_terms?
    user&.admin? == true || user&.can_manage_organization?(record)
  end

  def manage_courses?
    user&.admin? == true || user&.can_manage_organization?(record)
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.org_admin? && user.organization
        scope.where(id: user.organization_id)
      else
        scope.none
      end
    end
  end
end
