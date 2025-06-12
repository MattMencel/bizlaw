# frozen_string_literal: true

class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invitation, only: [ :edit, :update, :destroy, :resend, :revoke ]
  before_action :authorize_invitation_management!, except: [ :index ]

  def index
    @invitations = policy_scope(Invitation).includes(:organization, :invited_by)
                                          .order(created_at: :desc)
                                          .page(params[:page])
  end

  def new
    @invitation = Invitation.new
    @organizations = policy_scope(Organization)
    authorize @invitation
  end

  def create
    @invitation = build_invitation
    authorize @invitation

    if @invitation.save
      InvitationMailer.invitation_email(@invitation).deliver_later
      redirect_to invitations_path, notice: "Invitation sent successfully"
    else
      @organizations = policy_scope(Organization)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @invitation
    @organizations = policy_scope(Organization)
  end

  def update
    authorize @invitation

    if @invitation.update(invitation_params)
      redirect_to invitations_path, notice: "Invitation updated successfully"
    else
      @organizations = policy_scope(Organization)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @invitation

    if @invitation.destroy
      redirect_to invitations_path, notice: "Invitation deleted successfully"
    else
      redirect_to invitations_path, alert: "Unable to delete invitation"
    end
  end

  def resend
    authorize @invitation

    if @invitation.pending? && @invitation.resend!
      InvitationMailer.invitation_email(@invitation).deliver_later
      redirect_to invitations_path, notice: "Invitation resent successfully"
    else
      redirect_to invitations_path, alert: "Unable to resend invitation"
    end
  end

  def revoke
    authorize @invitation

    if @invitation.revoke!
      redirect_to invitations_path, notice: "Invitation revoked successfully"
    else
      redirect_to invitations_path, alert: "Unable to revoke invitation"
    end
  end

  def new_shareable
    @invitation = Invitation.new(shareable: true)
    @organizations = policy_scope(Organization)
    authorize @invitation
  end

  def create_shareable
    @invitation = build_shareable_invitation
    authorize @invitation

    if @invitation.save
      redirect_to invitations_path, notice: "Shareable invitation link created successfully"
    else
      @organizations = policy_scope(Organization)
      render :new_shareable, status: :unprocessable_entity
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find(params[:id])
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role, :organization_id, :org_admin)
  end

  def shareable_invitation_params
    params.require(:invitation).permit(:role, :organization_id, :org_admin)
  end

  def build_invitation
    attrs = invitation_params.merge(
      invited_by: current_user,
      shareable: false
    )

    # Handle orgAdmin role - convert to instructor with org_admin flag
    if attrs[:role] == "orgAdmin"
      attrs[:role] = "instructor"
      attrs[:org_admin] = true
    end

    Invitation.new(attrs)
  end

  def build_shareable_invitation
    attrs = shareable_invitation_params.merge(
      invited_by: current_user,
      shareable: true,
      email: nil # Shareable invitations don't have a specific email
    )

    # Handle orgAdmin role - convert to instructor with org_admin flag
    if attrs[:role] == "orgAdmin"
      attrs[:role] = "instructor"
      attrs[:org_admin] = true
    end

    Invitation.new(attrs)
  end

  def authorize_invitation_management!
    unless current_user.admin? || current_user.org_admin?
      redirect_to root_path, alert: "You are not authorized to perform this action"
    end
  end
end
