# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  def index?
    user&.admin? == true
  end

  def show?
    user&.admin? == true
  end

  def create?
    user&.admin? == true
  end

  def update?
    user&.admin? == true
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

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
