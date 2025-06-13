require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "invitation_email" do
    let(:mail) { InvitationMailer.invitation_email }

    it "renders the headers" do
      expect(mail.subject).to eq("Invitation email")
      expect(mail.to).to eq([ "to@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end
end
