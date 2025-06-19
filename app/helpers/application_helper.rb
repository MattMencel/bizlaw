module ApplicationHelper
  def sortable_column_header(column, title, path_method = nil)
    path_method ||= request.path
    direction = (params[:sort] == column && params[:direction] == "asc") ? "desc" : "asc"

    css_class = "text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:text-gray-700"
    css_class += " text-blue-600" if params[:sort] == column

    link_to path_method,
      {sort: column, direction: direction}.merge(request.query_parameters.except("sort", "direction")),
      {class: css_class} do
      content = title.html_safe
      if params[:sort] == column
        arrow = (params[:direction] == "asc") ? " ↑" : " ↓"
        content += arrow.html_safe
      end
      content
    end
  end

  # Admin settings helpers
  def setting_icon(category)
    case category
    when "general"
      content_tag :svg, viewBox: "0 0 24 24", fill: "currentColor", class: "h-6 w-6 text-white" do
        content_tag :path, "", d: "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"
      end
    when "security"
      content_tag :svg, viewBox: "0 0 24 24", fill: "currentColor", class: "h-6 w-6 text-white" do
        content_tag :path, "", d: "M18,8h-1V6c0-2.76-2.24-5-5-5S7,3.24,7,6v2H6c-1.1,0-2,0.9-2,2v10c0,1.1,0.9,2,2,2h12c1.1,0,2-0.9,2-2V10C20,8.9,19.1,8,18,8z M12,17c-1.1,0-2-0.9-2-2s0.9-2,2-2s2,0.9,2,2S13.1,17,12,17z M15.1,8H8.9V6c0-1.71,1.39-3.1,3.1-3.1s3.1,1.39,3.1,3.1V8z"
      end
    when "email"
      content_tag :svg, viewBox: "0 0 24 24", fill: "currentColor", class: "h-6 w-6 text-white" do
        content_tag :path, "", d: "M20,4H4C2.9,4,2.01,4.9,2.01,6L2,18c0,1.1,0.9,2,2,2h16c1.1,0,2-0.9,2-2V6C22,4.9,21.1,4,20,4z M20,8l-8,5L4,8V6l8,5l8-5V8z"
      end
    when "features"
      content_tag :svg, viewBox: "0 0 24 24", fill: "currentColor", class: "h-6 w-6 text-white" do
        content_tag :path, "", d: "M12,2l3.09,6.26L22,9.27l-5,4.87L18.18,22L12,18.77L5.82,22L7,14.14L2,9.27l6.91-1.01L12,2z"
      end
    when "integrations"
      content_tag :svg, viewBox: "0 0 24 24", fill: "currentColor", class: "h-6 w-6 text-white" do
        content_tag :path, "", d: "M19,13h-6v6h-2v-6H5v-2h6V5h2v6h6V13z"
      end
    else
      content_tag :svg, viewBox: "0 0 24 24", fill: "currentColor", class: "h-6 w-6 text-white" do
        content_tag :path, "", d: "M12,15.5A3.5,3.5 0 0,1 8.5,12A3.5,3.5 0 0,1 12,8.5a3.5,3.5 0 0,1 3.5,3.5A3.5,3.5 0 0,1 12,15.5M19.43,12.97C19.47,12.65 19.5,12.33 19.5,12C19.5,11.67 19.47,11.34 19.43,11L21.54,9.37C21.73,9.22 21.78,8.95 21.66,8.73L19.66,5.27C19.54,5.05 19.27,4.96 19.05,5.05L16.56,6.05C16.04,5.66 15.5,5.32 14.87,5.07L14.5,2.42C14.46,2.18 14.25,2 14,2H10C9.75,2 9.54,2.18 9.5,2.42L9.13,5.07C8.5,5.32 7.96,5.66 7.44,6.05L4.95,5.05C4.73,4.96 4.46,5.05 4.34,5.27L2.34,8.73C2.22,8.95 2.27,9.22 2.46,9.37L4.57,11C4.53,11.34 4.5,11.67 4.5,12C4.5,12.33 4.53,12.65 4.57,12.97L2.46,14.63C2.27,14.78 2.22,15.05 2.34,15.27L4.34,18.73C4.46,18.95 4.73,19.03 4.95,18.95L7.44,17.94C7.96,18.34 8.5,18.68 9.13,18.93L9.5,21.58C9.54,21.82 9.75,22 10,22H14C14.25,22 14.46,21.82 14.5,21.58L14.87,18.93C15.5,18.68 16.04,18.34 16.56,17.94L19.05,18.95C19.27,19.03 19.54,18.95 19.66,18.73L21.66,15.27C21.78,15.05 21.73,14.78 21.54,14.63L19.43,12.97Z"
      end
    end
  end

  def setting_icon_bg_class(category)
    case category
    when "general"
      "bg-blue-500"
    when "security"
      "bg-red-500"
    when "email"
      "bg-green-500"
    when "features"
      "bg-yellow-500"
    when "integrations"
      "bg-purple-500"
    else
      "bg-gray-500"
    end
  end

  def setting_description(category)
    case category
    when "general"
      "Configure basic application settings, maintenance mode, and contact information."
    when "security"
      "Manage authentication settings, password policies, and security features."
    when "email"
      "Configure SMTP settings and email delivery options."
    when "features"
      "Enable or disable platform features and functionality."
    when "integrations"
      "Configure external services and API integrations."
    else
      "System configuration options."
    end
  end
end
