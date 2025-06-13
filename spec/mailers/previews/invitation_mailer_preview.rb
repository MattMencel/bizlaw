# Preview all emails at http://localhost:3000/rails/mailers/invitation_mailer_mailer
class InvitationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/invitation_mailer_mailer/invitation_email
  def invitation_email
    InvitationMailer.invitation_email
  end
end
