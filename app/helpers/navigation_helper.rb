# Navigation Helper for role-based navigation and context management
module NavigationHelper
  # Get current user's active case
  def current_user_case
    return nil unless user_signed_in?

    # Check session for active case
    if session[:active_case_id].present?
      current_user.cases.find_by(id: session[:active_case_id])
    else
      # Default to first available case
      current_user.cases.active.first
    end
  end

  # Get current user's active team
  def current_user_team
    return nil unless current_user_case

    # Check session for active team
    if session[:active_team_id].present?
      current_user_case.teams.joins(:users).where(users: { id: current_user.id }).find_by(id: session[:active_team_id])
    else
      # Default to first team in current case
      current_user_case.teams.joins(:users).where(users: { id: current_user.id }).first
    end
  end

  # Check if user can access navigation section
  def can_access_section?(section_name)
    return false unless user_signed_in?

    case section_name.to_s
    when "legal_workspace"
      true # All authenticated users
    when "case_files"
      true # All authenticated users
    when "negotiations"
      true # All authenticated users
    when "administration"
      current_user.admin? || current_user.org_admin? || current_user.instructor?
    when "personal"
      true # All authenticated users
    else
      false
    end
  end

  # Check if user can access specific navigation item
  def can_access_nav_item?(item_path)
    return false unless user_signed_in?

    case item_path
    when admin_users_path, admin_organization_path
      current_user.admin? || current_user.org_admin?
    when admin_settings_path
      current_user.admin?
    when courses_path
      current_user.instructor? || current_user.admin? || current_user.org_admin?
    when invitations_path
      current_user.admin? || current_user.org_admin?
    else
      true # Default to accessible for authenticated users
    end
  rescue
    # If path doesn't exist, assume not accessible
    false
  end

  # Get case status color for display
  def case_status_color(status)
    case status&.to_s
    when "ready", "active"
      "text-green-400"
    when "pending", "waiting"
      "text-yellow-400"
    when "attention_needed", "overdue"
      "text-red-400"
    when "in_progress"
      "text-blue-400"
    else
      "text-gray-400"
    end
  end

  # Get case status dot color for display
  def case_status_dot_color(status)
    case status&.to_s
    when "ready", "active"
      "bg-green-400"
    when "pending", "waiting"
      "bg-yellow-400"
    when "attention_needed", "overdue"
      "bg-red-400"
    when "in_progress"
      "bg-blue-400"
    else
      "bg-gray-400"
    end
  end

  # Get navigation item count/badge
  def nav_item_badge(item_type)
    return nil unless user_signed_in?

    case item_type.to_s
    when "invitations"
      if current_user.admin? || current_user.org_admin?
        Invitation.pending.count
      end
    when "notifications"
      # Could implement notification system later
      nil
    when "deadlines"
      # Count approaching deadlines
      if current_user_case
        current_user_case.upcoming_deadlines.count
      end
    else
      nil
    end
  end

  # Check if navigation item is currently active
  def nav_item_active?(path)
    return false unless path

    begin
      current_page?(path)
    rescue ActionController::UrlGenerationError
      # Path doesn't exist, not active
      false
    end
  end

  # Generate navigation item classes with active state
  def nav_item_classes(path, size: "md", is_active: nil)
    is_active = nav_item_active?(path) if is_active.nil?

    base_classes = case size
    when "sm"
                     "flex items-center px-2 py-1.5 text-xs rounded-sm"
    when "lg"
                     "flex items-center px-4 py-3 text-base rounded-md"
    else
                     "flex items-center px-3 py-2 text-sm rounded-md"
    end

    state_classes = if is_active
                      "bg-blue-600 text-white"
    else
                      "text-gray-300 hover:bg-gray-700 hover:text-white"
    end

    "#{base_classes} #{state_classes} transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-blue-500 group"
  end

  # Get icon size based on navigation item size
  def nav_icon_size(size)
    case size
    when "sm"
      "h-4 w-4"
    when "lg"
      "h-6 w-6"
    else
      "h-5 w-5"
    end
  end

  # Get context switcher display data
  def context_switcher_data
    {
      current_case: current_user_case,
      current_team: current_user_team,
      case_phase: current_user_case&.current_phase,
      current_round: current_user_case&.current_round,
      total_rounds: current_user_case&.total_rounds,
      team_status: current_user_case&.team_status_for_user(current_user),
      user_role: current_user&.primary_role
    }
  end

  # Get available cases for context switching
  def available_cases_for_switching
    return [] unless user_signed_in?

    current_user.cases.active.includes(:teams, :users).limit(10)
  end

  # Get available teams for context switching within current case
  def available_teams_for_switching
    return [] unless current_user_case

    current_user_case.teams.includes(:users).where.not(id: current_user_team&.id)
  end

  # Get recently viewed cases
  def recently_viewed_cases
    return [] unless user_signed_in?

    # This would typically come from a tracking system
    # For now, return empty array - can be implemented later
    []
  end

  # Navigation section icons mapping
  def navigation_section_icon(section_name)
    case section_name.to_s
    when "legal_workspace"
      "home"
    when "case_files"
      "folder"
    when "negotiations"
      "scale"
    when "administration"
      "cog"
    when "personal"
      "user"
    else
      "question-mark-circle"
    end
  end

  # Check if navigation should be collapsed on mobile
  def mobile_navigation_collapsed?
    # Could check user preferences or screen size
    true
  end

  # Get navigation accessibility attributes
  def nav_accessibility_attrs(title, is_expanded: true)
    {
      "aria-label" => title,
      "aria-expanded" => is_expanded.to_s,
      "role" => "button",
      "tabindex" => "0"
    }
  end

  # Generate unique IDs for navigation elements
  def nav_element_id(prefix, identifier)
    "#{prefix}-#{identifier.to_s.parameterize}"
  end

  # Get navigation path for case-specific routes
  def case_nav_path(route_name)
    case_obj = current_user_case
    return "#" unless case_obj

    case route_name
    when "evidence_vault"
      # Check if evidence vault routes exist, otherwise link to case
      begin
        case_evidence_vault_index_path(case_obj)
      rescue
        case_path(case_obj)
      end
    when "negotiations"
      case_negotiations_path(case_obj)
    when "calculator"
      calculator_case_negotiations_path(case_obj)
    when "templates"
      templates_case_negotiations_path(case_obj)
    when "history"
      history_case_negotiations_path(case_obj)
    else
      cases_path
    end
  rescue
    cases_path
  end

  # Get safe navigation path (fallback to # if route doesn't exist)
  def safe_nav_path(path_helper, *args)
    begin
      send(path_helper, *args)
    rescue
      "#"
    end
  end

  # Check if user has any administrative privileges
  def has_admin_privileges?
    return false unless user_signed_in?

    current_user.admin? || current_user.org_admin? || current_user.instructor?
  end

  # Get navigation context for JavaScript
  def navigation_js_context
    {
      current_user_id: current_user&.id,
      current_case_id: current_user_case&.id,
      current_team_id: current_user_team&.id,
      user_roles: current_user&.roles || [],
      csrf_token: form_authenticity_token
    }.to_json.html_safe
  end
end
