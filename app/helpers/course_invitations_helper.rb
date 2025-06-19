# frozen_string_literal: true

module CourseInvitationsHelper
  def qr_code_image_tag(invitation, size: 200, alt: "QR Code for course invitation")
    # Use SVG instead of PNG for better compatibility and visibility
    content_tag :div,
      class: "qr-code-container border border-gray-200 rounded-lg inline-block p-4 bg-white",
      style: "width: #{size + 32}px; height: #{size + 32}px;" do
      qr_code_svg(invitation, size: size, css_class: "qr-code w-full h-full")
    end
  end

  def qr_code_svg(invitation, size: 200, css_class: "qr-code")
    svg_content = invitation.qr_code_svg(size: size)
    # Add CSS class to the SVG
    svg_with_class = svg_content.gsub("<svg", "<svg class=\"#{css_class}\"")
    raw svg_with_class
  end

  def qr_code_download_link(invitation, format: "png", size: 300, text: nil, css_class: "btn btn-outline")
    text ||= "Download QR Code (#{format.upcase})"

    link_to text,
      qr_code_course_invitation_path(invitation.token, format: format, size: size),
      class: css_class,
      target: "_blank",
      data: {turbo: false}, rel: "noopener"
  end

  def invitation_sharing_options(invitation)
    content_tag :div, class: "invitation-sharing space-y-4" do
      concat content_tag(:h4, "Share this invitation:", class: "text-lg font-semibold text-gray-900")

      concat content_tag(:div, class: "space-y-2") do
        # Invitation URL
        concat content_tag(:div, class: "flex items-center space-x-2") do
          concat content_tag(:label, "Link:", class: "text-sm font-medium text-gray-700 w-16")
          concat text_field_tag("invitation_url", invitation.invitation_url,
            readonly: true,
            class: "flex-1 px-3 py-1 border border-gray-300 rounded text-sm",
            onclick: "this.select();")
          concat button_tag("Copy",
            onclick: "navigator.clipboard.writeText('#{invitation.invitation_url}'); this.textContent='Copied!'; setTimeout(() => this.textContent='Copy', 2000);",
            class: "px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700")
        end

        # Invitation Code
        concat content_tag(:div, class: "flex items-center space-x-2") do
          concat content_tag(:label, "Code:", class: "text-sm font-medium text-gray-700 w-16")
          concat text_field_tag("invitation_code", invitation.token,
            readonly: true,
            class: "w-32 px-3 py-1 border border-gray-300 rounded text-sm font-mono text-center",
            onclick: "this.select();")
          concat button_tag("Copy",
            onclick: "navigator.clipboard.writeText('#{invitation.token}'); this.textContent='Copied!'; setTimeout(() => this.textContent='Copy', 2000);",
            class: "px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700")
        end
      end
    end
  end

  def invitation_status_badge(invitation)
    status = invitation.status

    case status
    when "active"
      content_tag :span, "Active", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    when "expired"
      content_tag :span, "Expired", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800"
    when "usage_exceeded"
      content_tag :span, "Usage Exceeded", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
    when "inactive"
      content_tag :span, "Inactive", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
    else
      content_tag :span, status.humanize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
    end
  end
end
