# frozen_string_literal: true

class Api::V1::CaseMaterialsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_case
  before_action :set_case_material, only: [:show, :update, :destroy, :download]
  before_action :ensure_case_access

  # GET /api/v1/cases/:case_id/case_materials
  # List case materials with team-specific filtering
  def index
    @case_materials = policy_scope(@case.documents)
                       .includes(:created_by, file_attachment: :blob)
                       .where(document_type: case_material_types)

    # Filter by team access permissions
    @case_materials = filter_materials_by_team_access(@case_materials)
    
    # Apply search and category filters
    @case_materials = apply_search_filters(@case_materials)
    
    # Sort by category and creation date
    @case_materials = @case_materials.order(:category, :created_at)

    render json: {
      data: @case_materials.map do |material|
        {
          id: material.id,
          title: material.title,
          description: material.description,
          category: material.category,
          document_type: material.document_type,
          file_name: material.file.filename.to_s,
          file_size: material.file.byte_size,
          content_type: material.file.content_type,
          uploaded_by: material.created_by.full_name,
          uploaded_at: material.created_at,
          access_level: material.access_level,
          team_restricted: material.team_restrictions.present?,
          searchable_content: material.searchable_content,
          annotations_count: material.annotations&.size || 0,
          tags: material.tags || []
        }
      end,
      meta: {
        total_materials: @case_materials.count,
        categories: case_material_categories,
        current_user_team: current_user_team&.name,
        access_permissions: calculate_access_permissions
      }
    }
  end

  # GET /api/v1/cases/:case_id/case_materials/:id
  # Get detailed case material information
  def show
    authorize @case_material, :show?

    render json: {
      data: {
        id: @case_material.id,
        title: @case_material.title,
        description: @case_material.description,
        category: @case_material.category,
        document_type: @case_material.document_type,
        file_name: @case_material.file.filename.to_s,
        file_size: @case_material.file.byte_size,
        content_type: @case_material.file.content_type,
        uploaded_by: @case_material.created_by.full_name,
        uploaded_at: @case_material.created_at,
        access_level: @case_material.access_level,
        team_restrictions: @case_material.team_restrictions || {},
        searchable_content: @case_material.searchable_content,
        annotations: @case_material.annotations || [],
        tags: @case_material.tags || [],
        download_url: case_material_download_url(@case, @case_material),
        can_edit: policy(@case_material).update?,
        can_delete: policy(@case_material).destroy?,
        can_annotate: can_annotate_material?(@case_material)
      }
    }
  end

  # POST /api/v1/cases/:case_id/case_materials
  # Upload new case material
  def create
    @case_material = @case.documents.build(case_material_params)
    @case_material.created_by = current_user
    @case_material.documentable = @case
    
    # Set default category if not provided
    @case_material.category ||= determine_default_category(@case_material)
    
    authorize @case_material

    if @case_material.save
      # Process document for search indexing
      ProcessCaseMaterialJob.perform_later(@case_material) if should_process_content?

      render json: {
        data: {
          id: @case_material.id,
          title: @case_material.title,
          message: "Case material uploaded successfully"
        }
      }, status: :created
    else
      render json: { 
        error: "Failed to upload case material",
        details: @case_material.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/cases/:case_id/case_materials/:id
  # Update case material metadata and access controls
  def update
    authorize @case_material

    if @case_material.update(case_material_update_params)
      render json: {
        data: {
          id: @case_material.id,
          title: @case_material.title,
          message: "Case material updated successfully"
        }
      }
    else
      render json: { 
        error: "Failed to update case material",
        details: @case_material.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/cases/:case_id/case_materials/:id
  # Delete case material (soft delete)
  def destroy
    authorize @case_material

    if @case_material.destroy
      render json: { message: "Case material deleted successfully" }
    else
      render json: { error: "Failed to delete case material" }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/cases/:case_id/case_materials/:id/download
  # Download case material file
  def download
    authorize @case_material, :show?

    if @case_material.file.attached?
      # Log the download for audit purposes
      log_material_access(@case_material, 'download')
      
      redirect_to rails_blob_url(@case_material.file, disposition: "attachment")
    else
      render json: { error: "File not found" }, status: :not_found
    end
  end

  # POST /api/v1/cases/:case_id/case_materials/:id/annotate
  # Add annotation to case material
  def annotate
    authorize @case_material, :update?

    annotation = {
      id: SecureRandom.uuid,
      user_id: current_user.id,
      user_name: current_user.full_name,
      team_id: current_user_team&.id,
      team_name: current_user_team&.name,
      content: params[:content],
      page_number: params[:page_number],
      position: params[:position] || {},
      created_at: Time.current,
      updated_at: Time.current
    }

    annotations = @case_material.annotations || []
    annotations << annotation

    if @case_material.update(annotations: annotations)
      render json: {
        data: {
          annotation: annotation,
          message: "Annotation added successfully"
        }
      }
    else
      render json: { error: "Failed to add annotation" }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/cases/:case_id/case_materials/search
  # Search case materials
  def search
    query = params[:query]
    return render json: { data: [], meta: { query: query } } if query.blank?

    @results = search_case_materials(query)
    
    render json: {
      data: @results.map do |material|
        {
          id: material.id,
          title: material.title,
          category: material.category,
          file_name: material.file.filename.to_s,
          relevance_score: calculate_relevance_score(material, query),
          matching_content: extract_matching_content(material, query),
          uploaded_at: material.created_at
        }
      end,
      meta: {
        query: query,
        total_results: @results.count,
        search_time: calculate_search_time
      }
    }
  end

  # GET /api/v1/cases/:case_id/case_materials/categories
  # Get available material categories
  def categories
    render json: {
      data: {
        categories: case_material_categories,
        counts: calculate_category_counts
      }
    }
  end

  private

  def set_case
    @case = Case.find(params[:case_id])
  end

  def set_case_material
    @case_material = @case.documents.find(params[:id])
  end

  def ensure_case_access
    unless policy(@case).show?
      render json: { error: "Access denied to this case" }, status: :forbidden
    end
  end

  def current_user_team
    @current_user_team ||= current_user.teams.joins(:case_teams).where(case_teams: { case: @case }).first
  end

  def case_material_params
    permitted_params = params.require(:case_material).permit(
      :title, :description, :category, :access_level, :file,
      team_restrictions: {}, tags: []
    )
    
    # Sanitize nested and array attributes
    permitted_params[:team_restrictions] = sanitize_team_restrictions(permitted_params[:team_restrictions])
    permitted_params[:tags] = sanitize_tags(permitted_params[:tags])
    
    # Override document_type to case material type
    permitted_params[:document_type] = 'resource'
    
    permitted_params
  end

  def case_material_update_params
    params.require(:case_material).permit(
      :title, :description, :category, :access_level,
      team_restrictions: {}, tags: []
    )
  end

  def case_material_types
    %w[resource template assignment] # Document types that are case materials
  end

  def case_material_categories
    [
      'case_facts',
      'legal_precedents', 
      'evidence_documents',
      'witness_statements',
      'expert_reports',
      'company_policies',
      'communications',
      'financial_records',
      'legal_briefs',
      'settlement_history',
      'reference_materials'
    ]
  end

  def filter_materials_by_team_access(materials)
    return materials unless current_user_team

    # Filter based on access level and team restrictions
    materials.where(
      "access_level = ? OR access_level = ? OR (team_restrictions ? ?)",
      'public',
      'case_teams',
      current_user_team.id.to_s
    )
  end

  def apply_search_filters(materials)
    materials = materials.where(category: params[:category]) if params[:category].present?
    materials = materials.where("title ILIKE ? OR searchable_content ILIKE ?", 
                               "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    materials = materials.where("tags @> ?", [params[:tag]].to_json) if params[:tag].present?
    materials
  end

  def determine_default_category(material)
    # Analyze filename to suggest category
    filename = material.file.filename.to_s.downcase
    
    case filename
    when /policy|handbook|manual/
      'company_policies'
    when /statement|testimony|deposition/
      'witness_statements'
    when /expert|report|analysis/
      'expert_reports'
    when /email|communication|correspondence/
      'communications'
    when /financial|budget|salary|compensation/
      'financial_records'
    when /precedent|case.*law|ruling/
      'legal_precedents'
    when /brief|motion|pleading/
      'legal_briefs'
    else
      'evidence_documents'
    end
  end

  def search_case_materials(query)
    accessible_materials = filter_materials_by_team_access(
      @case.documents.where(document_type: case_material_types)
    )

    # Search in title, description, searchable content, and tags
    accessible_materials.where(
      "title ILIKE ? OR description ILIKE ? OR searchable_content ILIKE ? OR tags::text ILIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
    ).limit(50)
  end

  def calculate_relevance_score(material, query)
    score = 0
    query_terms = query.downcase.split(/\s+/)
    
    query_terms.each do |term|
      score += 10 if material.title.downcase.include?(term)
      score += 5 if material.description&.downcase&.include?(term)
      score += 3 if material.searchable_content&.downcase&.include?(term)
      score += 2 if material.tags&.any? { |tag| tag.downcase.include?(term) }
    end
    
    score
  end

  def extract_matching_content(material, query)
    content = material.searchable_content || ""
    query_terms = query.downcase.split(/\s+/)
    
    matches = []
    query_terms.each do |term|
      if content.downcase.include?(term)
        # Extract surrounding context (50 chars before and after)
        index = content.downcase.index(term)
        start_pos = [0, index - 50].max
        end_pos = [content.length, index + term.length + 50].min
        context = content[start_pos...end_pos]
        matches << "...#{context}..."
      end
    end
    
    matches.first(3) # Return up to 3 matching excerpts
  end

  def calculate_search_time
    # Placeholder for actual search timing
    "#{rand(50..200)}ms"
  end

  def calculate_access_permissions
    team = current_user_team
    return {} unless team

    {
      can_upload: policy(@case).update?,
      can_view_all: current_user.role_instructor? || current_user.role_admin?,
      team_name: team.name,
      team_role: team.case_teams.find_by(case: @case)&.role
    }
  end

  def calculate_category_counts
    accessible_materials = filter_materials_by_team_access(
      @case.documents.where(document_type: case_material_types)
    )

    case_material_categories.map do |category|
      [category, accessible_materials.where(category: category).count]
    end.to_h
  end

  def can_annotate_material?(material)
    policy(material).update? && current_user_team.present?
  end

  def log_material_access(material, action)
    # Create audit log entry
    @case.case_events.create!(
      user: current_user,
      event_type: 'document_access',
      metadata: {
        document_id: material.id,
        document_title: material.title,
        action: action,
        team_id: current_user_team&.id
      }
    )
  end

  def should_process_content?
    # Only process text-based documents for search indexing
    %w[application/pdf text/plain text/markdown].include?(@case_material.file.content_type)
  end
  private

  def sanitize_team_restrictions(team_restrictions)
    return {} unless team_restrictions.is_a?(Hash)
    team_restrictions.slice(:allowed_teams, :restricted_teams) # Example keys to allow
  end

  def sanitize_tags(tags)
    return [] unless tags.is_a?(Array)
    tags.map(&:to_s).reject(&:blank?) # Ensure tags are strings and not empty
  end
end