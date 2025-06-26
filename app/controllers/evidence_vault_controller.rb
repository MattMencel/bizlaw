# frozen_string_literal: true

class EvidenceVaultController < ApplicationController
  before_action :authenticate_user!
  before_action :set_case
  before_action :set_team_membership
  before_action :authorize_case_access!
  before_action :set_document, only: [:show, :annotate, :update_tags]

  def index
    @documents = accessible_documents.includes(:created_by, :updated_by)
    @document_categories = @documents.group(:category).count
    @current_team = @team_membership&.team
    @total_documents = @documents.count

    respond_to do |format|
      format.html
      format.json { render json: evidence_vault_data }
    end
  end

  def search
    @search_query = params[:q]&.strip
    @category_filter = params[:category]
    @tag_filters = Array(params[:tags]).compact_blank
    @page = [params[:page]&.to_i || 1, 1].max
    @per_page = [params[:per_page]&.to_i || 25, 100].min

    @documents = build_search_query
    @search_results = paginate_results(@documents)

    render json: {
      documents: serialize_documents(@search_results),
      total_results: @documents.count,
      search_query: @search_query,
      category_filter: @category_filter,
      tag_filters: @tag_filters,
      available_categories: available_categories,
      available_tags: available_tags,
      pagination: pagination_metadata
    }
  end

  def show
    authorize @document, :show?

    render json: {
      id: @document.id,
      title: @document.title,
      description: @document.description,
      category: @document.category,
      tags: @document.tags || [],
      access_level: @document.access_level,
      created_at: @document.created_at,
      updated_at: @document.updated_at,
      created_by: {
        id: @document.created_by.id,
        name: @document.created_by.full_name
      },
      annotations: serialize_annotations(@document.annotations || []),
      download_url: download_document_path(@document),
      can_edit: policy(@document).update?,
      can_annotate: policy(@document).annotate?
    }
  end

  def annotate
    authorize @document, :annotate?

    annotation_params = params.require(:annotation).permit(:content, :page, :position_x, :position_y)

    if annotation_params[:content].blank?
      return render json: {errors: ["Content cannot be blank"]}, status: :unprocessable_entity
    end

    if annotation_params[:page].present? && annotation_params[:page].to_i < 1
      return render json: {errors: ["Page must be a positive number"]}, status: :unprocessable_entity
    end

    new_annotation = {
      id: SecureRandom.uuid,
      user_id: current_user.id,
      user_name: current_user.full_name,
      team_id: @team_membership&.team_id,
      team_name: @team_membership&.team&.name,
      content: sanitize_annotation_content(annotation_params[:content]),
      page: annotation_params[:page]&.to_i || 1,
      position_x: annotation_params[:position_x]&.to_f,
      position_y: annotation_params[:position_y]&.to_f,
      created_at: Time.current.iso8601
    }

    current_annotations = @document.annotations || []
    current_annotations << new_annotation

    if @document.update(annotations: current_annotations)
      # Log annotation activity
      CaseEvent.create!(
        case: @case,
        user: current_user,
        event_type: "document_annotated",
        description: "Added annotation to #{@document.title}",
        metadata: {document_id: @document.id, annotation_id: new_annotation[:id]}
      )

      render json: {
        annotation: new_annotation,
        total_annotations: current_annotations.count,
        success: true
      }
    else
      render json: {errors: @document.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def update_tags
    authorize @document, :update?

    new_tags = Array(params[:tags]).map(&:strip).compact_blank.uniq

    if new_tags.any? { |tag| tag.match?(/\A\s*\z/) }
      return render json: {errors: ["Tags cannot be blank"]}, status: :unprocessable_entity
    end

    if @document.update(tags: new_tags)
      # Log tag update activity
      CaseEvent.create!(
        case: @case,
        user: current_user,
        event_type: "document_tagged",
        description: "Updated tags for #{@document.title}",
        metadata: {document_id: @document.id, tags: new_tags}
      )

      render json: {
        tags: new_tags,
        success: true
      }
    else
      render json: {errors: @document.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def create_bundle
    bundle_params = params.require(:bundle).permit(:name, document_ids: [])

    if bundle_params[:name].blank?
      return render json: {errors: ["Bundle name cannot be blank"]}, status: :unprocessable_entity
    end

    document_ids = Array(bundle_params[:document_ids]).compact_blank
    if document_ids.empty?
      return render json: {errors: ["Bundle must contain at least one document"]}, status: :unprocessable_entity
    end

    # Only include documents the user can actually access
    accessible_document_ids = accessible_documents.where(id: document_ids).pluck(:id)

    if accessible_document_ids.empty?
      return render json: {errors: ["No accessible documents found"]}, status: :unprocessable_entity
    end

    bundle_documents = accessible_documents.where(id: accessible_document_ids)

    bundle_data = {
      id: SecureRandom.uuid,
      name: bundle_params[:name],
      created_by: current_user.id,
      created_by_name: current_user.full_name,
      team_id: @team_membership&.team_id,
      team_name: @team_membership&.team&.name,
      created_at: Time.current.iso8601,
      document_count: bundle_documents.count,
      documents: serialize_documents(bundle_documents)
    }

    # Log bundle creation
    CaseEvent.create!(
      case: @case,
      user: current_user,
      event_type: "evidence_bundle_created",
      description: "Created evidence bundle: #{bundle_params[:name]}",
      metadata: {
        bundle_id: bundle_data[:id],
        document_count: bundle_documents.count,
        document_ids: accessible_document_ids
      }
    )

    render json: bundle_data, status: :created
  end

  private

  def set_case
    @case = Case.find(params[:case_id])
  rescue ActiveRecord::RecordNotFound
    render json: {error: "Case not found"}, status: :not_found
  end

  def set_team_membership
    @team_membership = current_user.team_members
      .joins(:team)
      .joins(simulation: :case)
      .where(simulations: {case_id: @case.id})
      .first
  end

  def authorize_case_access!
    unless @team_membership || current_user.instructor? || current_user.admin?
      render json: {error: "Access denied"}, status: :forbidden
    end
  end

  def set_document
    @document = accessible_documents.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {error: "Document not found or access denied"}, status: :forbidden
  end

  def accessible_documents
    base_query = @case.documents.includes(:created_by, :updated_by)

    if current_user.admin? || current_user.instructor?
      # Admins and instructors see all documents
      base_query
    elsif @team_membership
      # Students see documents based on access level and team restrictions
      base_query.where(
        "(access_level = 'public') OR " \
        "(access_level = 'case_teams') OR " \
        "(access_level = 'team_restricted' AND (team_restrictions IS NULL OR " \
        "team_restrictions->'allowed_teams' ? :team_id))",
        team_id: @team_membership.team_id.to_s
      )
    else
      # No access for users not on case teams
      base_query.none
    end
  end

  def build_search_query
    query = accessible_documents

    if @search_query.present?
      # Use PostgreSQL full-text search with ranking
      query = query.where(
        "searchable_content ILIKE :query OR title ILIKE :query OR " \
        "description ILIKE :query OR tags::text ILIKE :query",
        query: "%#{@search_query}%"
      )
    end

    if @category_filter.present?
      query = query.where(category: @category_filter)
    end

    if @tag_filters.any?
      # Search for documents that have all specified tags
      @tag_filters.each do |tag|
        query = query.where("tags ? :tag", tag: tag)
      end
    end

    query.order(:title)
  end

  def paginate_results(query)
    offset = (@page - 1) * @per_page
    query.limit(@per_page).offset(offset)
  end

  def serialize_documents(documents)
    documents.map do |doc|
      {
        id: doc.id,
        title: doc.title,
        description: doc.description,
        category: doc.category,
        tags: doc.tags || [],
        access_level: doc.access_level,
        created_at: doc.created_at,
        updated_at: doc.updated_at,
        created_by: doc.created_by&.full_name,
        has_annotations: doc.annotations.present?,
        annotation_count: doc.annotations&.count || 0,
        download_url: download_document_path(doc),
        can_edit: policy(doc).update?,
        can_annotate: policy(doc).annotate?
      }
    end
  end

  def serialize_annotations(annotations)
    annotations.sort_by { |a| a["created_at"] }.map do |annotation|
      {
        id: annotation["id"],
        user_id: annotation["user_id"],
        user_name: annotation["user_name"],
        team_name: annotation["team_name"],
        content: annotation["content"],
        page: annotation["page"],
        position_x: annotation["position_x"],
        position_y: annotation["position_y"],
        created_at: annotation["created_at"],
        can_delete: annotation["user_id"] == current_user.id || current_user.instructor? || current_user.admin?
      }
    end
  end

  def available_categories
    accessible_documents.distinct.pluck(:category).compact.sort
  end

  def available_tags
    # Extract all unique tags from JSONB arrays
    tag_query = accessible_documents.where.not(tags: nil)
    tag_query.pluck("jsonb_array_elements_text(tags)").uniq.sort
  end

  def pagination_metadata
    total_results = @documents.count
    total_pages = (total_results.to_f / @per_page).ceil

    {
      current_page: @page,
      per_page: @per_page,
      total_results: total_results,
      total_pages: total_pages,
      has_next_page: @page < total_pages,
      has_prev_page: @page > 1
    }
  end

  def evidence_vault_data
    {
      case_id: @case.id,
      case_title: @case.title,
      team_name: @team_membership&.team&.name,
      team_role: @team_membership&.role,
      documents: serialize_documents(@documents),
      document_categories: @document_categories,
      total_documents: @total_documents,
      available_categories: available_categories,
      available_tags: available_tags,
      user_permissions: {
        can_upload: policy(Document).create?,
        can_create_bundles: true,
        is_instructor: current_user.instructor?
      }
    }
  end

  def sanitize_annotation_content(content)
    # Basic HTML sanitization for annotation content
    ActionController::Base.helpers.sanitize(content, tags: %w[p br strong em u])
  end

  def download_document_path(document)
    # This should integrate with your existing document download system
    # Placeholder for the actual download URL generation
    "/documents/#{document.id}/download"
  end
end
