# API Controller for context switching functionality
class Api::V1::ContextController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :find_case, only: [:switch_case]
  before_action :find_team, only: [:switch_team]

  # GET /api/v1/context/current
  def current
    context_data = {
      case: serialize_case(current_user_case),
      team: serialize_team(current_user_team),
      user_role: current_user.primary_role,
      permissions: user_permissions
    }

    render json: context_data
  end

  # PATCH /api/v1/context/switch_case
  def switch_case
    if @case.nil?
      render json: {error: "Case not found"}, status: :not_found
      return
    end

    unless current_user.can_access_case?(@case)
      render json: {error: "Access denied"}, status: :forbidden
      return
    end

    # Update session
    session[:active_case_id] = @case.id

    # Find appropriate team for user in this case
    new_team = @case.teams.joins(:users).where(users: {id: current_user.id}).first
    session[:active_team_id] = new_team&.id

    # Track context switch
    track_context_switch("case", @case.id)

    context_data = {
      case: serialize_case(@case),
      team: serialize_team(new_team),
      user_role: current_user.role_in_case(@case),
      success: true
    }

    render json: context_data
  end

  # PATCH /api/v1/context/switch_team
  def switch_team
    if @team.nil?
      render json: {error: "Team not found"}, status: :not_found
      return
    end

    unless current_user.can_access_team?(@team)
      render json: {error: "Access denied"}, status: :forbidden
      return
    end

    # Update session
    session[:active_team_id] = @team.id
    session[:active_case_id] = @team.case_id

    # Track context switch
    track_context_switch("team", @team.id)

    context_data = {
      case: serialize_case(@team.case),
      team: serialize_team(@team),
      user_role: current_user.role_in_team(@team),
      success: true
    }

    render json: context_data
  end

  # GET /api/v1/context/search
  def search
    query = params[:q]&.strip

    if query.blank? || query.length < 2
      render json: {cases: [], teams: []}
      return
    end

    # Search cases
    cases = current_user.cases
      .where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
      .limit(5)
      .includes(:teams)

    # Search teams
    teams = Team.joins(:case, :users)
      .where(users: {id: current_user.id})
      .where("teams.name ILIKE ? OR cases.title ILIKE ?", "%#{query}%", "%#{query}%")
      .limit(5)
      .includes(:case)

    results = {
      cases: cases.map { |c| serialize_case(c) },
      teams: teams.map { |t| serialize_team(t) }
    }

    render json: results
  end

  # GET /api/v1/context/available
  def available
    available_data = {
      cases: current_user.cases.active.limit(10).map { |c| serialize_case(c) },
      teams: current_user.teams.includes(:case).limit(10).map { |t| serialize_team(t) }
    }

    render json: available_data
  end

  private

  def find_case
    @case = current_user.cases.find_by(id: params[:case_id])
  end

  def find_team
    @team = current_user.teams.find_by(id: params[:team_id])
  end

  def serialize_case(case_obj)
    return nil unless case_obj

    {
      id: case_obj.id,
      title: case_obj.title,
      description: case_obj.description,
      current_phase: case_obj.current_phase,
      current_round: case_obj.current_round,
      total_rounds: case_obj.total_rounds,
      status: case_obj.status,
      team_status: case_obj.team_status_for_user(current_user),
      user_team: serialize_team(case_obj.user_team_for(current_user)),
      created_at: case_obj.created_at,
      updated_at: case_obj.updated_at
    }
  end

  def serialize_team(team_obj)
    return nil unless team_obj

    {
      id: team_obj.id,
      name: team_obj.name,
      team_type: team_obj.case_role,
      case_id: team_obj.primary_case&.id,
      case_title: team_obj.primary_case&.title,
      user_role: current_user.role_in_team(team_obj),
      member_count: team_obj.users.count,
      created_at: team_obj.created_at,
      updated_at: team_obj.updated_at
    }
  end

  def user_permissions
    {
      admin: current_user.admin?,
      org_admin: current_user.org_admin?,
      instructor: current_user.instructor?,
      student: current_user.student?,
      can_switch_cases: current_user.cases.count > 1,
      can_switch_teams: current_user_case&.teams&.count.to_i > 1
    }
  end

  def track_context_switch(switch_type, entity_id)
    # Track context switching for analytics
    # Could be implemented with a dedicated tracking service
    Rails.logger.info "User #{current_user.id} switched #{switch_type} to #{entity_id}"

    # Update last_accessed timestamps (if columns exist)
    case switch_type
    when "case"
      # Case.where(id: entity_id).update_all(last_accessed_at: Time.current) if Case.column_names.include?('last_accessed_at')
    when "team"
      # Team.where(id: entity_id).update_all(last_accessed_at: Time.current) if Team.column_names.include?('last_accessed_at')
    end
  end

  def current_user_case
    @current_user_case ||= if session[:active_case_id].present?
      current_user.cases.find_by(id: session[:active_case_id])
    else
      current_user.cases.active.first
    end
  end

  def current_user_team
    @current_user_team ||= begin
      return nil unless current_user_case

      if session[:active_team_id].present?
        current_user_case.teams.joins(:users).where(users: {id: current_user.id}).find_by(id: session[:active_team_id])
      else
        current_user_case.teams.joins(:users).where(users: {id: current_user.id}).first
      end
    end
  end
end
