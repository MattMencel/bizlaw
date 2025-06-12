# frozen_string_literal: true

class InvitationAcceptanceController < ApplicationController
  before_action :set_invitation_by_token
  before_action :validate_invitation

  def show
    if user_signed_in?
      # User is already signed in, just process the invitation
      if process_invitation
        redirect_to dashboard_path, notice: "Your account has been updated with new permissions"
      else
        redirect_to root_path, alert: "Unable to process invitation"
      end
    else
      # Show registration/login form
      @user = User.new(email: @invitation.email)
      render "show"
    end
  end

  def accept
    if user_signed_in?
      redirect_to_processed_invitation
    else
      create_user_and_accept_invitation
    end
  end

  def show_shareable
    if user_signed_in?
      # User is already signed in, just process the invitation
      if process_invitation
        redirect_to dashboard_path, notice: "Your account has been updated with new permissions"
      else
        redirect_to root_path, alert: "Unable to process invitation"
      end
    else
      # Show registration form for shareable invitation
      @user = User.new
      @shareable = true
      render "show_shareable"
    end
  end

  def accept_shareable
    if user_signed_in?
      redirect_to_processed_invitation
    else
      create_user_and_accept_shareable_invitation
    end
  end

  private

  def set_invitation_by_token
    @invitation = Invitation.find_by_token(params[:token])

    unless @invitation
      redirect_to root_path, alert: "Invalid invitation link"
      nil
    end
  end

  def validate_invitation
    unless @invitation.can_be_accepted?
      if @invitation.expired?
        redirect_to contact_path, alert: "This invitation has expired"
      elsif @invitation.revoked?
        redirect_to root_path, alert: "This invitation is no longer valid"
      else
        redirect_to root_path, alert: "This invitation cannot be accepted"
      end
      nil
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def process_invitation
    return false unless @invitation.can_be_accepted?

    current_user.transaction do
      # Update user with invitation details
      current_user.update!(
        role: @invitation.role,
        organization: @invitation.organization,
        org_admin: @invitation.org_admin?
      )

      @invitation.accept!(current_user)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to process invitation: #{e.message}"
    false
  end

  def create_user_and_accept_invitation
    @user = User.new(user_params.merge(
      role: @invitation.role,
      organization: @invitation.organization,
      org_admin: @invitation.org_admin?
    ))

    if @user.save
      @invitation.accept!(@user)
      sign_in(@user)
      redirect_to dashboard_path, notice: "Welcome! Your account has been created successfully"
    else
      render "show", status: :unprocessable_entity
    end
  end

  def create_user_and_accept_shareable_invitation
    @user = User.new(user_params.merge(
      role: @invitation.role,
      organization: @invitation.organization,
      org_admin: @invitation.org_admin?
    ))

    if @user.save
      @invitation.accept!(@user)
      sign_in(@user)
      redirect_to dashboard_path, notice: "Welcome! Your account has been created successfully"
    else
      @shareable = true
      render "show_shareable", status: :unprocessable_entity
    end
  end

  def redirect_to_processed_invitation
    if process_invitation
      redirect_to dashboard_path, notice: "Your account has been updated with new permissions"
    else
      redirect_to root_path, alert: "Unable to process invitation"
    end
  end

  def contact_path
    # Return a contact or support page path, fallback to root
    respond_to?(:contact, true) ? contact_url : root_path
  end
end
