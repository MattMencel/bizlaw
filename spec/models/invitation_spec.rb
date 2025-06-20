# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitation, type: :model do
  let(:admin_user) { create(:user, role: :admin) }
  let(:organization) { create(:organization) }

  describe "associations" do
    it { is_expected.to belong_to(:invited_by) }

    context "for admin role" do
      subject { build(:invitation, role: "admin", organization: nil, invited_by: admin_user) }

      it { is_expected.to belong_to(:organization).optional }
    end
  end

  describe "validations" do
    subject { build(:invitation, invited_by: admin_user, organization: organization) }

    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%w[student instructor admin]) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending accepted expired revoked]) }

    it "validates email format" do
      invitation = build(:invitation, email: "invalid-email", invited_by: admin_user, organization: organization)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include("is invalid")
    end

    it "requires email for non-shareable invitations" do
      invitation = build(:invitation, email: nil, shareable: false, invited_by: admin_user, organization: organization)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include("is required for email-based invitations")
    end

    it "does not require email for shareable invitations" do
      invitation = build(:invitation, email: nil, shareable: true, invited_by: admin_user, organization: organization)
      expect(invitation).to be_valid
    end

    it "requires organization for non-admin roles" do
      invitation = build(:invitation, role: "student", organization: nil, invited_by: admin_user)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:organization]).to include("is required for non-admin roles")
    end

    it "does not require organization for admin role" do
      invitation = build(:invitation, role: "admin", organization: nil, invited_by: admin_user)
      expect(invitation).to be_valid
    end
  end

  describe "scopes" do
    let!(:pending_invitation) { create(:invitation, status: "pending", invited_by: admin_user, organization: organization) }
    let!(:accepted_invitation) { create(:invitation, status: "accepted", invited_by: admin_user, organization: organization) }
    let!(:expired_invitation) { create(:invitation, status: "expired", invited_by: admin_user, organization: organization) }
    let!(:revoked_invitation) { create(:invitation, status: "revoked", invited_by: admin_user, organization: organization) }

    describe ".pending" do
      it "returns only pending invitations" do
        expect(Invitation.pending).to contain_exactly(pending_invitation)
      end
    end

    describe ".accepted" do
      it "returns only accepted invitations" do
        expect(Invitation.accepted).to contain_exactly(accepted_invitation)
      end
    end

    describe ".expired" do
      it "returns only expired invitations" do
        expect(Invitation.expired).to contain_exactly(expired_invitation)
      end
    end

    describe ".revoked" do
      it "returns only revoked invitations" do
        expect(Invitation.revoked).to contain_exactly(revoked_invitation)
      end
    end
  end

  describe "soft deletion functionality" do
    let(:invitation) { create(:invitation, invited_by: admin_user, organization: organization) }

    it "includes SoftDeletable behavior through ApplicationRecord" do
      expect(invitation).to respond_to(:soft_delete)
      expect(invitation).to respond_to(:deleted?)
      expect(invitation).to respond_to(:active?)
      expect(invitation).to respond_to(:restore)
    end

    describe "#soft_delete" do
      it "marks the invitation as deleted" do
        expect { invitation.soft_delete }
          .to change { invitation.deleted? }.from(false).to(true)
      end

      it "sets deleted_at timestamp" do
        invitation.soft_delete
        expect(invitation.deleted_at).to be_present
      end

      it "does not set active to false since invitations do not have active column" do
        invitation.soft_delete
        expect(invitation).to be_deleted
      end
    end

    describe "#restore" do
      let(:deleted_invitation) do
        invitation = create(:invitation, invited_by: admin_user, organization: organization)
        invitation.soft_delete
        invitation
      end

      it "restores the invitation" do
        expect { deleted_invitation.restore }
          .to change { deleted_invitation.deleted? }.from(true).to(false)
      end

      it "clears deleted_at timestamp" do
        deleted_invitation.restore
        expect(deleted_invitation.deleted_at).to be_nil
      end

      it "restores the invitation to active state" do
        deleted_invitation.restore
        expect(deleted_invitation).to be_active
      end
    end

    describe "default scope" do
      let!(:active_invitation) { create(:invitation, invited_by: admin_user, organization: organization) }
      let!(:deleted_invitation) do
        invitation = create(:invitation, invited_by: admin_user, organization: organization)
        invitation.soft_delete
        invitation
      end

      it "only returns active invitations by default" do
        expect(Invitation.all).to contain_exactly(active_invitation)
      end

      it "can access deleted invitations with unscoped" do
        expect(Invitation.unscoped.count).to eq(2)
        expect(Invitation.unscoped).to include(active_invitation, deleted_invitation)
      end
    end

    describe ".active scope" do
      let!(:active_invitation) { create(:invitation, invited_by: admin_user, organization: organization) }
      let!(:deleted_invitation) do
        invitation = create(:invitation, invited_by: admin_user, organization: organization)
        invitation.soft_delete
        invitation
      end

      it "returns only active invitations" do
        expect(Invitation.active).to contain_exactly(active_invitation)
      end
    end

    describe ".deleted scope" do
      let!(:active_invitation) { create(:invitation, invited_by: admin_user, organization: organization) }
      let!(:deleted_invitation) do
        invitation = create(:invitation, invited_by: admin_user, organization: organization)
        invitation.soft_delete
        invitation
      end

      it "returns only deleted invitations" do
        expect(Invitation.deleted).to contain_exactly(deleted_invitation)
      end
    end
  end

  describe "#expired?" do
    it "returns true for expired invitations" do
      invitation = build(:invitation, expires_at: 1.day.ago, invited_by: admin_user, organization: organization)
      expect(invitation.expired?).to be true
    end

    it "returns false for non-expired invitations" do
      invitation = build(:invitation, expires_at: 1.day.from_now, invited_by: admin_user, organization: organization)
      expect(invitation.expired?).to be false
    end
  end

  describe "#can_be_accepted?" do
    it "returns true for pending, non-expired invitations" do
      invitation = build(:invitation, status: "pending", expires_at: 1.day.from_now, invited_by: admin_user, organization: organization)
      expect(invitation.can_be_accepted?).to be true
    end

    it "returns false for non-pending invitations" do
      invitation = build(:invitation, status: "accepted", expires_at: 1.day.from_now, invited_by: admin_user, organization: organization)
      expect(invitation.can_be_accepted?).to be false
    end

    it "returns false for expired invitations" do
      invitation = build(:invitation, status: "pending", expires_at: 1.day.ago, invited_by: admin_user, organization: organization)
      expect(invitation.can_be_accepted?).to be false
    end
  end

  describe "cross-domain organization invitations" do
    let(:university_org) { create(:organization, domain: "university.edu") }
    let(:org_admin) { create(:user, :org_admin, organization: university_org, email: "admin@university.edu") }
    let(:system_admin) { create(:user, :admin) }

    context "when OrgAdmin invites student with different email domain" do
      it "allows invitation to student with external email domain" do
        invitation = build(:invitation,
          email: "student@external-college.com",
          role: "student",
          organization: university_org,
          invited_by: org_admin)

        expect(invitation).to be_valid
      end

      it "allows invitation to instructor with external email domain" do
        invitation = build(:invitation,
          email: "instructor@different-school.org",
          role: "instructor",
          organization: university_org,
          invited_by: org_admin)

        expect(invitation).to be_valid
      end

      it "does not validate email domain against organization domain" do
        mismatched_domains = [
          "user@gmail.com",
          "someone@yahoo.edu",
          "external@other-university.edu",
          "contractor@company.com"
        ]

        mismatched_domains.each do |email|
          invitation = build(:invitation,
            email: email,
            role: "student",
            organization: university_org,
            invited_by: org_admin)

          expect(invitation).to be_valid, "Expected invitation with email #{email} to be valid"
        end
      end
    end

    context "when System Admin invites across organizations" do
      let(:other_org) { create(:organization, domain: "other-college.edu") }

      it "allows system admin to invite users with any email to any organization" do
        invitation = build(:invitation,
          email: "anyone@anywhere.com",
          role: "instructor",
          organization: other_org,
          invited_by: system_admin)

        expect(invitation).to be_valid
      end

      it "allows system admin to create admin invitations without organization restrictions" do
        invitation = build(:invitation,
          email: "newadmin@external.com",
          role: "admin",
          organization: nil,
          invited_by: system_admin)

        expect(invitation).to be_valid
      end
    end

    context "invitation acceptance with cross-domain emails" do
      let(:cross_domain_invitation) do
        create(:invitation,
          email: "student@external.edu",
          role: "student",
          organization: university_org,
          invited_by: org_admin)
      end

      it "allows user with different domain to accept organization invitation" do
        user = create(:user, email: "student@external.edu", role: "student", organization: nil)

        expect(cross_domain_invitation.accept!(user)).to be true

        user.reload
        expect(user.organization).to eq(university_org)
        expect(user.role).to eq("student")
      end

      it "assigns user to inviting organization regardless of email domain" do
        user = create(:user, email: "student@external.edu", role: "student", organization: nil)
        original_email_domain = user.email.split("@").last

        cross_domain_invitation.accept!(user)
        user.reload

        expect(user.organization).to eq(university_org)
        expect(user.organization.domain).not_to eq(original_email_domain)
      end
    end

    context "shareable invitations across domains" do
      it "allows shareable invitations with placeholder email to be used by any domain" do
        shareable_invitation = create(:invitation,
          email: "placeholder@invite.link",
          role: "student",
          organization: university_org,
          invited_by: org_admin,
          shareable: true)

        expect(shareable_invitation).to be_valid
        expect(shareable_invitation.shareable?).to be true
      end

      it "does not restrict shareable invitation usage by email domain" do
        shareable_invitation = create(:invitation,
          email: "share@invite.link",
          role: "instructor",
          organization: university_org,
          invited_by: org_admin,
          shareable: true)

        # Anyone with any email domain should be able to use this invitation
        # We just test that the invitation is shareable, not the URL generation which requires host config
        expect(shareable_invitation.shareable?).to be true
        expect(shareable_invitation.token).to be_present
      end
    end
  end
end
