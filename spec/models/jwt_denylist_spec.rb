# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JwtDenylist, type: :model do
  describe 'table configuration' do
    it 'uses correct table name' do
      expect(JwtDenylist.table_name).to eq('jwt_denylist')
    end
  end

  describe 'Devise JWT integration' do
    it 'includes Devise JWT Denylist strategy' do
      expect(JwtDenylist.ancestors).to include(Devise::JWT::RevocationStrategies::Denylist)
    end

    it 'responds to denylist interface methods' do
      expect(JwtDenylist).to respond_to(:jwt_revoked?)
      expect(JwtDenylist).to respond_to(:revoke_jwt)
    end
  end

  describe 'JWT revocation functionality' do
    let(:payload) { { 'jti' => 'unique-jwt-id', 'exp' => 1.hour.from_now.to_i } }
    let(:user) { create(:user) }

    it 'can revoke a JWT token' do
      expect { JwtDenylist.revoke_jwt(payload, user) }.not_to raise_error
    end

    it 'creates a denylist entry when revoking JWT' do
      expect {
        JwtDenylist.revoke_jwt(payload, user)
      }.to change(JwtDenylist, :count).by(1)
    end

    it 'identifies revoked tokens' do
      JwtDenylist.revoke_jwt(payload, user)
      expect(JwtDenylist.jwt_revoked?(payload, user)).to be true
    end

    it 'identifies non-revoked tokens' do
      expect(JwtDenylist.jwt_revoked?(payload, user)).to be false
    end

    it 'handles multiple revocations for same user' do
      payload1 = { 'jti' => 'jwt-id-1', 'exp' => 1.hour.from_now.to_i }
      payload2 = { 'jti' => 'jwt-id-2', 'exp' => 2.hours.from_now.to_i }

      JwtDenylist.revoke_jwt(payload1, user)
      JwtDenylist.revoke_jwt(payload2, user)

      expect(JwtDenylist.jwt_revoked?(payload1, user)).to be true
      expect(JwtDenylist.jwt_revoked?(payload2, user)).to be true
    end
  end

  describe 'database operations' do
    it 'creates valid denylist entries' do
      entry = JwtDenylist.create!(jti: 'test-jti', exp: 1.hour.from_now)
      expect(entry).to be_persisted
      expect(entry.jti).to eq('test-jti')
    end

    it 'handles cleanup of expired tokens' do
      # Create an expired token
      expired_entry = JwtDenylist.create!(
        jti: 'expired-jti',
        exp: 1.hour.ago
      )

      # Create a valid token
      valid_entry = JwtDenylist.create!(
        jti: 'valid-jti',
        exp: 1.hour.from_now
      )

      expect(JwtDenylist.count).to eq(2)

      # Note: Actual cleanup would be handled by a background job
      # This test just verifies the data structure supports it
      expect(JwtDenylist.where('exp < ?', Time.current).count).to eq(1)
      expect(JwtDenylist.where('exp >= ?', Time.current).count).to eq(1)
    end
  end

  describe 'security considerations' do
    it 'prevents duplicate jti entries' do
      jti = 'duplicate-test-jti'
      exp_time = 1.hour.from_now

      JwtDenylist.create!(jti: jti, exp: exp_time)

      expect {
        JwtDenylist.create!(jti: jti, exp: exp_time)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'handles edge case payloads gracefully' do
      # Test with minimal payload
      minimal_payload = { 'jti' => 'minimal-jwt' }
      expect { JwtDenylist.jwt_revoked?(minimal_payload, user) }.not_to raise_error

      # Test with nil payload
      expect { JwtDenylist.jwt_revoked?(nil, user) }.not_to raise_error

      # Test with empty payload
      expect { JwtDenylist.jwt_revoked?({}, user) }.not_to raise_error
    end
  end
end
