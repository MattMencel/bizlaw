# frozen_string_literal: true

require 'rails_helper'

RSpec.describe License, type: :model do
  describe 'validations' do
    subject { build(:license) }

    it { is_expected.to validate_presence_of(:license_key) }
    it { is_expected.to validate_presence_of(:organization_name) }
    it { is_expected.to validate_presence_of(:contact_email) }
    it { is_expected.to validate_presence_of(:license_type) }
    it { is_expected.to validate_presence_of(:signature) }
    it { is_expected.to validate_uniqueness_of(:license_key) }
  end

  describe 'associations' do
    it { is_expected.to have_one(:organization) }
    it { is_expected.to have_many(:users).through(:organization) }
  end

  describe 'enums' do
    it do
      is_expected.to define_enum_for(:license_type)
        .with_values(free: 'free', starter: 'starter', professional: 'professional', enterprise: 'enterprise')
        .with_prefix(:license_type)
    end
  end

  describe 'scopes' do
    let!(:active_license) { create(:license, active: true) }
    let!(:inactive_license) { create(:license, active: false) }
    let!(:expired_license) { create(:license, :expired) }
    let!(:expiring_license) { create(:license, :expiring_soon) }

    describe '.active' do
      it 'returns only active licenses' do
        expect(License.active).to include(active_license)
        expect(License.active).not_to include(inactive_license)
      end
    end

    describe '.expired' do
      it 'returns only expired licenses' do
        expect(License.expired).to include(expired_license)
        expect(License.expired).not_to include(active_license)
      end
    end

    describe '.expiring_soon' do
      it 'returns licenses expiring within 30 days' do
        expect(License.expiring_soon).to include(expiring_license)
        expect(License.expiring_soon).not_to include(active_license)
      end
    end
  end

  describe '#expired?' do
    it 'returns true for expired licenses' do
      license = build(:license, expires_at: 1.day.ago.to_date)
      expect(license.expired?).to be true
    end

    it 'returns false for non-expired licenses' do
      license = build(:license, expires_at: 1.day.from_now.to_date)
      expect(license.expired?).to be false
    end

    it 'returns false for licenses without expiry date' do
      license = build(:license, expires_at: nil)
      expect(license.expired?).to be false
    end
  end

  describe '#expiring_soon?' do
    it 'returns true for licenses expiring within 30 days' do
      license = build(:license, expires_at: 15.days.from_now.to_date)
      expect(license.expiring_soon?).to be true
    end

    it 'returns false for licenses not expiring soon' do
      license = build(:license, expires_at: 60.days.from_now.to_date)
      expect(license.expiring_soon?).to be false
    end
  end

  describe '#valid_signature?' do
    it 'returns true for valid signature' do
      license = create(:license)
      expect(license.valid_signature?).to be true
    end

    it 'returns false for invalid signature' do
      license = create(:license)
      license.update_column(:signature, 'invalid_signature')
      expect(license.valid_signature?).to be false
    end
  end

  describe '#within_limits?' do
    let(:organization) { create(:organization) }
    let(:license) { create(:license, max_instructors: 2, max_students: 5, max_courses: 3) }

    before do
      organization.update!(license: license)
    end

    it 'returns true when within limits' do
      create(:user, :instructor, organization: organization)
      create_list(:user, 3, :student, organization: organization)
      create_list(:course, 2, organization: organization, instructor: organization.instructors.first)

      expect(license.within_limits?).to be true
    end

    it 'returns false when exceeding instructor limit' do
      create_list(:user, 3, :instructor, organization: organization)
      expect(license.within_limits?).to be false
    end

    it 'returns false when exceeding student limit' do
      create_list(:user, 6, :student, organization: organization)
      expect(license.within_limits?).to be false
    end
  end

  describe '#feature_enabled?' do
    context 'with free license' do
      let(:license) { build(:license, license_type: 'free') }

      it 'returns false for premium features' do
        expect(license.feature_enabled?('advanced_analytics')).to be false
        expect(license.feature_enabled?('custom_branding')).to be false
        expect(license.feature_enabled?('api_access')).to be false
      end
    end

    context 'with professional license' do
      let(:license) { build(:license, license_type: 'professional') }

      it 'returns true for professional features' do
        expect(license.feature_enabled?('advanced_analytics')).to be true
        expect(license.feature_enabled?('custom_branding')).to be true
        expect(license.feature_enabled?('api_access')).to be true
      end
    end

    context 'with enterprise license' do
      let(:license) { build(:license, license_type: 'enterprise') }

      it 'returns true for all features' do
        expect(license.feature_enabled?('advanced_analytics')).to be true
        expect(license.feature_enabled?('custom_branding')).to be true
        expect(license.feature_enabled?('api_access')).to be true
        expect(license.feature_enabled?('priority_support')).to be true
      end
    end
  end

  describe '.validate_license_key' do
    let!(:valid_license) { create(:license, license_key: 'VALID-KEY-123') }
    let!(:expired_license) { create(:license, :expired, license_key: 'EXPIRED-KEY-456') }
    let!(:inactive_license) { create(:license, :inactive, license_key: 'INACTIVE-KEY-789') }

    it 'returns license for valid key' do
      expect(License.validate_license_key('VALID-KEY-123')).to eq(valid_license)
    end

    it 'returns nil for expired license' do
      expect(License.validate_license_key('EXPIRED-KEY-456')).to be_nil
    end

    it 'returns nil for inactive license' do
      expect(License.validate_license_key('INACTIVE-KEY-789')).to be_nil
    end

    it 'returns nil for non-existent key' do
      expect(License.validate_license_key('NON-EXISTENT')).to be_nil
    end
  end

  describe '.default_free_license' do
    it 'creates a default free license' do
      expect { License.default_free_license }.to change(License, :count).by(1)
    end

    it 'returns existing default license if it exists' do
      first_call = License.default_free_license
      second_call = License.default_free_license
      expect(first_call).to eq(second_call)
    end
  end
end
