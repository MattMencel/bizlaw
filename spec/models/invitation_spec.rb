# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invitation, type: :model do
  let(:admin_user) { create(:user, role: :admin) }
  let(:organization) { create(:organization) }

  describe 'associations' do
    it { is_expected.to belong_to(:invited_by) }

    context 'for admin role' do
      subject { build(:invitation, role: 'admin', organization: nil, invited_by: admin_user) }
      it { is_expected.to belong_to(:organization).optional }
    end
  end

  describe 'validations' do
    subject { build(:invitation, invited_by: admin_user, organization: organization) }

    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%w[student instructor admin]) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending accepted expired revoked]) }

    it 'validates email format' do
      invitation = build(:invitation, email: 'invalid-email', invited_by: admin_user, organization: organization)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include('is invalid')
    end

    it 'requires email for non-shareable invitations' do
      invitation = build(:invitation, email: nil, shareable: false, invited_by: admin_user, organization: organization)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include('is required for email-based invitations')
    end

    it 'does not require email for shareable invitations' do
      invitation = build(:invitation, email: nil, shareable: true, invited_by: admin_user, organization: organization)
      expect(invitation).to be_valid
    end

    it 'requires organization for non-admin roles' do
      invitation = build(:invitation, role: 'student', organization: nil, invited_by: admin_user)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:organization]).to include('is required for non-admin roles')
    end

    it 'does not require organization for admin role' do
      invitation = build(:invitation, role: 'admin', organization: nil, invited_by: admin_user)
      expect(invitation).to be_valid
    end
  end

  describe 'scopes' do
    let!(:pending_invitation) { create(:invitation, status: 'pending', invited_by: admin_user, organization: organization) }
    let!(:accepted_invitation) { create(:invitation, status: 'accepted', invited_by: admin_user, organization: organization) }
    let!(:expired_invitation) { create(:invitation, status: 'expired', invited_by: admin_user, organization: organization) }
    let!(:revoked_invitation) { create(:invitation, status: 'revoked', invited_by: admin_user, organization: organization) }

    describe '.pending' do
      it 'returns only pending invitations' do
        expect(Invitation.pending).to contain_exactly(pending_invitation)
      end
    end

    describe '.accepted' do
      it 'returns only accepted invitations' do
        expect(Invitation.accepted).to contain_exactly(accepted_invitation)
      end
    end

    describe '.expired' do
      it 'returns only expired invitations' do
        expect(Invitation.expired).to contain_exactly(expired_invitation)
      end
    end

    describe '.revoked' do
      it 'returns only revoked invitations' do
        expect(Invitation.revoked).to contain_exactly(revoked_invitation)
      end
    end
  end

  describe 'soft deletion functionality' do
    let(:invitation) { create(:invitation, invited_by: admin_user, organization: organization) }

    it 'includes SoftDeletable behavior through ApplicationRecord' do
      expect(invitation).to respond_to(:soft_delete)
      expect(invitation).to respond_to(:deleted?)
      expect(invitation).to respond_to(:active?)
      expect(invitation).to respond_to(:restore)
    end

    describe '#soft_delete' do
      it 'marks the invitation as deleted' do
        expect { invitation.soft_delete }
          .to change { invitation.deleted? }.from(false).to(true)
      end

      it 'sets deleted_at timestamp' do
        invitation.soft_delete
        expect(invitation.deleted_at).to be_present
      end

      it 'does not set active to false since invitations do not have active column' do
        invitation.soft_delete
        expect(invitation).to be_deleted
      end
    end

    describe '#restore' do
      let(:deleted_invitation) do
        invitation = create(:invitation, invited_by: admin_user, organization: organization)
        invitation.soft_delete
        invitation
      end

      it 'restores the invitation' do
        expect { deleted_invitation.restore }
          .to change { deleted_invitation.deleted? }.from(true).to(false)
      end

      it 'clears deleted_at timestamp' do
        deleted_invitation.restore
        expect(deleted_invitation.deleted_at).to be_nil
      end

      it 'restores the invitation to active state' do
        deleted_invitation.restore
        expect(deleted_invitation).to be_active
      end
    end

    describe 'default scope' do
      let!(:active_invitation) { create(:invitation, invited_by: admin_user, organization: organization) }
      let!(:deleted_invitation) do
        invitation = create(:invitation, invited_by: admin_user, organization: organization)
        invitation.soft_delete
        invitation
      end

      it 'only returns active invitations by default' do
        expect(Invitation.all).to contain_exactly(active_invitation)
      end

      it 'can access deleted invitations with unscoped' do
        expect(Invitation.unscoped.count).to eq(2)
        expect(Invitation.unscoped).to include(active_invitation, deleted_invitation)
      end
    end

    describe '.active scope' do
      let!(:active_invitation) { create(:invitation, invited_by: admin_user, organization: organization) }
      let!(:deleted_invitation) do
        invitation = create(:invitation, invited_by: admin_user, organization: organization)
        invitation.soft_delete
        invitation
      end

      it 'returns only active invitations' do
        expect(Invitation.active).to contain_exactly(active_invitation)
      end
    end

    describe '.deleted scope' do
      let!(:active_invitation) { create(:invitation, invited_by: admin_user, organization: organization) }
      let!(:deleted_invitation) do
        invitation = create(:invitation, invited_by: admin_user, organization: organization)
        invitation.soft_delete
        invitation
      end

      it 'returns only deleted invitations' do
        expect(Invitation.deleted).to contain_exactly(deleted_invitation)
      end
    end
  end

  describe '#expired?' do
    it 'returns true for expired invitations' do
      invitation = build(:invitation, expires_at: 1.day.ago, invited_by: admin_user, organization: organization)
      expect(invitation.expired?).to be true
    end

    it 'returns false for non-expired invitations' do
      invitation = build(:invitation, expires_at: 1.day.from_now, invited_by: admin_user, organization: organization)
      expect(invitation.expired?).to be false
    end
  end

  describe '#can_be_accepted?' do
    it 'returns true for pending, non-expired invitations' do
      invitation = build(:invitation, status: 'pending', expires_at: 1.day.from_now, invited_by: admin_user, organization: organization)
      expect(invitation.can_be_accepted?).to be true
    end

    it 'returns false for non-pending invitations' do
      invitation = build(:invitation, status: 'accepted', expires_at: 1.day.from_now, invited_by: admin_user, organization: organization)
      expect(invitation.can_be_accepted?).to be false
    end

    it 'returns false for expired invitations' do
      invitation = build(:invitation, status: 'pending', expires_at: 1.day.ago, invited_by: admin_user, organization: organization)
      expect(invitation.can_be_accepted?).to be false
    end
  end
end