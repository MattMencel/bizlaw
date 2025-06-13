# frozen_string_literal: true

class Api::V1::EvidenceReleasesController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_case
  before_action :set_evidence_release, only: [:show, :approve, :deny]
  before_action :ensure_case_access

  # GET /api/v1/cases/:case_id/evidence_releases
  # List evidence releases for a case
  def index
    @evidence_releases = @case.simulation.evidence_releases
                              .includes(:document, :requesting_team)
                              .order(:release_round, :scheduled_release_at)

    # Filter by team access if student
    unless current_user.role_instructor? || current_user.role_admin?
      user_team = current_user_team
      if user_team
        @evidence_releases = @evidence_releases.where(
          "requesting_team_id = ? OR auto_release = true",
          user_team.id
        )
      else
        @evidence_releases = @evidence_releases.auto_releases
      end
    end

    render json: {
      data: @evidence_releases.map do |release|
        {
          id: release.id,
          document_title: release.document.title,
          evidence_type: release.evidence_type,
          release_round: release.release_round,
          scheduled_release_at: release.scheduled_release_at,
          released_at: release.released_at,
          status: determine_release_status(release),
          team_requested: release.team_requested?,
          requesting_team: release.requesting_team&.name,
          impact_description: release.impact_description,
          auto_release: release.auto_release?,
          can_access: can_access_evidence?(release)
        }
      end,
      meta: {
        total_releases: @evidence_releases.count,
        pending_releases: @evidence_releases.pending_release.count,
        current_round: @case.simulation.current_round,
        evidence_types: EvidenceRelease::EVIDENCE_TYPES
      }
    }
  end

  # GET /api/v1/cases/:case_id/evidence_releases/:id
  # Get detailed evidence release information
  def show
    authorize_evidence_access!

    render json: {
      data: {
        id: @evidence_release.id,
        document: {
          id: @evidence_release.document.id,
          title: @evidence_release.document.title,
          description: @evidence_release.document.description,
          category: @evidence_release.document.category,
          file_name: @evidence_release.document.file.filename.to_s,
          download_url: can_download_evidence? ? evidence_download_url : nil
        },
        evidence_type: @evidence_release.evidence_type,
        release_round: @evidence_release.release_round,
        scheduled_release_at: @evidence_release.scheduled_release_at,
        released_at: @evidence_release.released_at,
        status: determine_release_status(@evidence_release),
        team_requested: @evidence_release.team_requested?,
        requesting_team: @evidence_release.requesting_team&.name,
        impact_description: @evidence_release.impact_description,
        release_conditions: @evidence_release.release_conditions,
        can_approve: can_approve_release?,
        can_deny: can_deny_release?,
        approval_history: extract_approval_history
      }
    }
  end

  # POST /api/v1/cases/:case_id/evidence_releases
  # Create a team request for evidence release
  def create
    @evidence_release = EvidenceRelease.create_team_request(
      @case.simulation,
      find_document,
      current_user_team,
      evidence_params[:evidence_type],
      evidence_params[:justification]
    )

    if @evidence_release.persisted?
      # Notify instructors of the request
      notify_instructors_of_request(@evidence_release)

      render json: {
        data: {
          id: @evidence_release.id,
          message: "Evidence request submitted successfully"
        }
      }, status: :created
    else
      render json: {
        error: "Failed to create evidence request",
        details: @evidence_release.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/cases/:case_id/evidence_releases/:id/approve
  # Approve a team evidence request (instructors only)
  def approve
    ensure_instructor!

    if @evidence_release.approve_team_request!(current_user)
      render json: {
        data: {
          id: @evidence_release.id,
          message: "Evidence request approved and released"
        }
      }
    else
      render json: { error: "Failed to approve evidence request" }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/cases/:case_id/evidence_releases/:id/deny
  # Deny a team evidence request (instructors only)
  def deny
    ensure_instructor!

    denial_reason = params[:reason] || "Request denied by instructor"
    
    if @evidence_release.deny_team_request!(current_user, denial_reason)
      render json: {
        data: {
          id: @evidence_release.id,
          message: "Evidence request denied",
          reason: denial_reason
        }
      }
    else
      render json: { error: "Failed to deny evidence request" }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/cases/:case_id/evidence_releases/schedule
  # Get evidence release schedule (instructors only)
  def schedule
    ensure_instructor!

    all_releases = @case.simulation.evidence_releases
                        .includes(:document, :requesting_team)
                        .order(:release_round, :scheduled_release_at)

    render json: {
      data: {
        automatic_releases: build_release_schedule(all_releases.auto_releases),
        team_requests: build_team_requests(all_releases.team_requests),
        release_calendar: build_release_calendar(all_releases)
      }
    }
  end

  # POST /api/v1/cases/:case_id/evidence_releases/schedule_automatic
  # Schedule automatic evidence release (instructors only)
  def schedule_automatic
    ensure_instructor!

    document = @case.documents.find(params[:document_id])
    
    @evidence_release = EvidenceRelease.schedule_automatic_release(
      @case.simulation,
      document,
      params[:release_round].to_i,
      params[:evidence_type],
      params[:impact_description]
    )

    if @evidence_release.persisted?
      render json: {
        data: {
          id: @evidence_release.id,
          message: "Automatic evidence release scheduled"
        }
      }, status: :created
    else
      render json: {
        error: "Failed to schedule evidence release",
        details: @evidence_release.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_case
    @case = Case.find(params[:case_id])
  end

  def set_evidence_release
    @evidence_release = @case.simulation.evidence_releases.find(params[:id])
  end

  def ensure_case_access
    unless policy(@case).show?
      render json: { error: "Access denied to this case" }, status: :forbidden
    end
  end

  def ensure_instructor!
    unless current_user.role_instructor? || current_user.role_admin?
      render json: { error: "Instructor access required" }, status: :forbidden
    end
  end

  def current_user_team
    @current_user_team ||= current_user.teams.joins(:case_teams).where(case_teams: { case: @case }).first
  end

  def evidence_params
    params.require(:evidence_release).permit(:evidence_type, :justification, :document_id)
  end

  def find_document
    @case.documents.find(evidence_params[:document_id])
  end

  def determine_release_status(release)
    return "released" if release.released?
    return "pending_approval" if release.team_requested? && !release.approved_for_release?
    return "denied" if release.release_conditions["denied_by"].present?
    return "scheduled" if release.auto_release?
    "pending"
  end

  def can_access_evidence?(release)
    return true if current_user.role_instructor? || current_user.role_admin?
    return true if release.released?
    return true if release.requesting_team == current_user_team
    false
  end

  def authorize_evidence_access!
    unless can_access_evidence?(@evidence_release)
      render json: { error: "Access denied to this evidence release" }, status: :forbidden
    end
  end

  def can_download_evidence?
    @evidence_release.released? && can_access_evidence?(@evidence_release)
  end

  def evidence_download_url
    return nil unless can_download_evidence?
    case_material_download_url(@case, @evidence_release.document)
  end

  def can_approve_release?
    (current_user.role_instructor? || current_user.role_admin?) && 
    @evidence_release.team_requested? && 
    !@evidence_release.released? &&
    @evidence_release.release_conditions["denied_by"].blank?
  end

  def can_deny_release?
    can_approve_release?
  end

  def extract_approval_history
    conditions = @evidence_release.release_conditions
    history = []

    if conditions["requested_at"]
      history << {
        action: "requested",
        user: @evidence_release.requesting_team&.name,
        timestamp: conditions["requested_at"],
        details: conditions["request_justification"]
      }
    end

    if conditions["approved_by"]
      approver = User.find_by(id: conditions["approved_by"])
      history << {
        action: "approved",
        user: approver&.full_name,
        timestamp: conditions["approved_at"],
        details: conditions["approval_reason"]
      }
    end

    if conditions["denied_by"]
      denier = User.find_by(id: conditions["denied_by"])
      history << {
        action: "denied",
        user: denier&.full_name,
        timestamp: conditions["denied_at"],
        details: conditions["denial_reason"]
      }
    end

    history
  end

  def notify_instructors_of_request(evidence_release)
    # Find all instructors associated with this case
    case_instructors = @case.course&.instructors || []
    
    case_instructors.each do |instructor|
      # In a real app, you'd use a proper notification system
      Rails.logger.info "Evidence request notification sent to #{instructor.email}"
    end
  end

  def build_release_schedule(auto_releases)
    auto_releases.group_by(&:release_round).map do |round, releases|
      {
        round: round,
        scheduled_date: releases.first&.scheduled_release_at&.to_date,
        evidence_count: releases.count,
        evidence_types: releases.pluck(:evidence_type).uniq
      }
    end
  end

  def build_team_requests(team_requests)
    team_requests.map do |request|
      {
        id: request.id,
        evidence_type: request.evidence_type,
        requesting_team: request.requesting_team&.name,
        requested_at: request.release_conditions["requested_at"],
        status: determine_release_status(request),
        justification: request.release_conditions["request_justification"]
      }
    end
  end

  def build_release_calendar(all_releases)
    calendar = {}
    
    all_releases.each do |release|
      date_key = if release.released?
                   release.released_at.to_date.to_s
                 elsif release.scheduled_release_at
                   release.scheduled_release_at.to_date.to_s
                 else
                   "unscheduled"
                 end
      
      calendar[date_key] ||= []
      calendar[date_key] << {
        id: release.id,
        evidence_type: release.evidence_type,
        type: release.team_requested? ? "team_request" : "automatic",
        status: determine_release_status(release)
      }
    end
    
    calendar
  end
end