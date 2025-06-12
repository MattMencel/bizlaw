class InvitationMailer < ApplicationMailer
  def invitation_email(invitation)
    @invitation = invitation
    @inviter = invitation.invited_by
    @organization = invitation.organization
    @role_display = invitation.org_admin? ? "Organization Admin" : invitation.role.humanize
    @accept_url = invitation.invitation_url

    mail(
      to: @invitation.email,
      subject: invitation_subject
    )
  end

  private

  def invitation_subject
    org_name = @organization&.name || "the platform"
    "You're invited to join #{org_name} as #{@role_display.downcase}"
  end
end
