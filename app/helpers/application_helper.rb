module ApplicationHelper
  def sortable_column_header(column, title, path_method = nil)
    path_method ||= request.path
    direction = (params[:sort] == column && params[:direction] == "asc") ? "desc" : "asc"

    css_class = "text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:text-gray-700"
    css_class += " text-blue-600" if params[:sort] == column

    link_to path_method,
            { sort: column, direction: direction }.merge(request.query_parameters.except("sort", "direction")),
            { class: css_class } do
      content = title.html_safe
      if params[:sort] == column
        arrow = params[:direction] == "asc" ? " ↑" : " ↓"
        content += arrow.html_safe
      end
      content
    end
  end
end
