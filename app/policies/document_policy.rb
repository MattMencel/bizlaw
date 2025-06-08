# frozen_string_literal: true

class DocumentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user_can_access_document?
  end

  def create?
    user_can_access_documentable?
  end

  def update?
    user_can_manage_document?
  end

  def destroy?
    user_can_manage_document?
  end

  def finalize?
    user_can_manage_document? && record.status == "draft"
  end

  def archive?
    user_can_manage_document? && record.status == "final"
  end

  private

  def user_can_access_document?
    return true if user.admin?
    return true if record.created_by_id == user.id

    user_can_access_documentable?
  end

  def user_can_manage_document?
    return true if user.admin?
    return true if record.created_by_id == user.id

    # Check if user can manage the associated documentable (case, team, etc.)
    case record.documentable_type
    when "Case"
      CasePolicy.new(user, record.documentable).update?
    when "Team"
      TeamPolicy.new(user, record.documentable).update?
    else
      false
    end
  end

  def user_can_access_documentable?
    case record.documentable_type
    when "Case"
      CasePolicy.new(user, record.documentable).show?
    when "Team"
      TeamPolicy.new(user, record.documentable).show?
    else
      false
    end
  end

  class Scope < Scope
    def resolve
      case user.role
      when "admin"
        scope.all
      when "instructor"
        scope.all
      when "student"
        # Students can access documents for cases/teams they're involved in
        case_ids = user.teams.joins(:cases).pluck("cases.id")
        team_ids = user.team_ids

        scope.where(
          "(documentable_type = 'Case' AND documentable_id IN (?)) OR " \
          "(documentable_type = 'Team' AND documentable_id IN (?)) OR " \
          "created_by_id = ?",
          case_ids, team_ids, user.id
        )
      else
        scope.none
      end
    end
  end
end
