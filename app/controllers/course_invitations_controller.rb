# frozen_string_literal: true

class CourseInvitationsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :find_invitation, only: [:show, :join]
  before_action :validate_invitation, only: [:show, :join]
  before_action :require_student, only: [:join]

  def show
    @course = @invitation.course
    @already_enrolled = current_user&.student? && @course.enrolled?(current_user)
  end

  def join
    @course = @invitation.course

    if @course.enrolled?(current_user)
      redirect_to @course, notice: "You are already enrolled in #{@course.display_name}."
      return
    end

    if @course.enroll_student(current_user, @invitation)
      redirect_to @course, notice: "Successfully enrolled in #{@course.display_name}!"
    else
      redirect_to course_invitation_path(@invitation.token),
        alert: "Unable to enroll in the course. Please try again or contact your instructor."
    end
  end

  # Public action for entering invite codes
  def enter_code
  end

  # Process invite code entry
  def process_code
    token = params[:token]&.strip&.upcase

    if token.blank?
      redirect_to enter_code_course_invitations_path, alert: "Please enter an invitation code."
      return
    end

    invitation = CourseInvitation.find_valid_invitation(token)

    if invitation
      redirect_to course_invitation_path(token)
    else
      redirect_to enter_code_course_invitations_path,
        alert: "Invalid or expired invitation code. Please check the code and try again."
    end
  end

  # Download QR code as PNG
  def qr_code
    invitation = CourseInvitation.find_by!(token: params[:token])
    size = params[:size]&.to_i || 300
    format = params[:format] || "png"

    # Authorization check - only course instructor/admin can download QR codes
    unless current_user&.admin? || invitation.course.instructor == current_user
      redirect_to courses_path, alert: "You are not authorized to access this QR code."
      return
    end

    case format.downcase
    when "png"
      png_data = invitation.qr_code_png(size: size)
      send_data png_data.to_s,
        type: "image/png",
        filename: "course_invitation_#{invitation.token}.png",
        disposition: "attachment"
    when "svg"
      svg_data = invitation.qr_code_svg(size: size)
      send_data svg_data,
        type: "image/svg+xml",
        filename: "course_invitation_#{invitation.token}.svg",
        disposition: "attachment"
    else
      redirect_to courses_path, alert: "Invalid QR code format requested."
    end
  end

  private

  def find_invitation
    @invitation = CourseInvitation.find_by!(token: params[:token] || params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to courses_path, alert: "Invitation not found."
  end

  def validate_invitation
    unless @invitation.can_be_used?
      case @invitation.status
      when "expired"
        redirect_to courses_path, alert: "This invitation has expired."
      when "usage_exceeded"
        redirect_to courses_path, alert: "This invitation has reached its usage limit."
      when "inactive"
        redirect_to courses_path, alert: "This invitation is no longer active."
      else
        redirect_to courses_path, alert: "This invitation is not valid."
      end
    end
  end

  def require_student
    unless current_user.student?
      redirect_to course_invitation_path(@invitation.token),
        alert: "Only students can enroll in courses."
    end
  end
end
