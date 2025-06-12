# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  def index?
    user.admin? || user.org_admin?
  end

  def show?
    false # Not used - invitations are accepted via token
  end

  def create?
    can_send_invitations?
  end

  def new?
    create?
  end

  def update?
    can_manage_invitation?
  end

  def edit?
    update?
  end

  def destroy?
    can_manage_invitation?
  end

  def resend?
    can_manage_invitation? && record.pending?
  end

  def revoke?
    can_manage_invitation? && record.pending?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        # Admin can see all invitations
        scope.all
      elsif user.org_admin?
        # OrgAdmin can see invitations for their organization
        scope.where(organization: user.organization)
      else
        # Others cannot see invitations
        scope.none
      end
    end
  end

  private

  def can_send_invitations?
    return false unless user

    # Admin can send any invitation
    return true if user.admin?

    # OrgAdmin can send invitations within their organization
    return true if user.org_admin?

    false
  end

  def can_manage_invitation?
    return false unless user
    return false unless record

    # Admin can manage all invitations
    return true if user.admin?

    # OrgAdmin can manage invitations for their organization
    if user.org_admin?
      return record.organization == user.organization
    end

    false
  end
end
