# frozen_string_literal: true

class CoursePolicy < ApplicationPolicy
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
    user.admin? || user.can_manage_organization?(record.organization) ||
      record.instructor_id == user.id
  end

  def destroy?
    user.admin? || user.can_manage_organization?(record.organization)
  end

  def assign_instructor?
    return false unless user.organization == record.organization
    user.admin? || user.can_manage_organization?(record.organization)
  end

  class Scope < Scope
    def resolve
      case user.role
      when "admin"
        scope.all
      when "instructor"
        if user.org_admin?
          scope.where(organization: user.organization)
        else
          scope.where(instructor: user).or(scope.where(organization: user.organization))
        end
      when "student"
        # Students can see courses in their organization or courses they're enrolled in
        scope.where(organization: user.organization)
      else
        scope.none
      end
    end
  end
end
