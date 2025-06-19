# frozen_string_literal: true

require "rails_helper"

RSpec.describe JwtDenylist, type: :model do
  describe "table configuration" do
    it "uses correct table name" do
      expect(described_class.table_name).to eq("jwt_denylist")
    end
  end

  describe "Devise JWT integration" do
    it "includes Devise JWT Denylist strategy" do
      expect(described_class.ancestors).to include(Devise::JWT::RevocationStrategies::Denylist)
    end

    it "responds to denylist interface methods" do
      expect(described_class).to respond_to(:jwt_revoked?)
      expect(described_class).to respond_to(:revoke_jwt)
    end
  end

  describe "JWT revocation functionality" do
    let(:payload) { {"jti" => "unique-jwt-id", "exp" => 1.hour.from_now.to_i} }
    let(:user) { create(:user) }

    it "can revoke a JWT token" do
      expect { described_class.revoke_jwt(payload, user) }.not_to raise_error
    end

    it "creates a denylist entry when revoking JWT" do
      expect {
        described_class.revoke_jwt(payload, user)
      }.to change(described_class, :count).by(1)
    end

    it "identifies revoked tokens" do
      described_class.revoke_jwt(payload, user)
      expect(described_class.jwt_revoked?(payload, user)).to be true
    end

    it "identifies non-revoked tokens" do
      expect(described_class.jwt_revoked?(payload, user)).to be false
    end

    it "handles multiple revocations for same user" do
      payload1 = {"jti" => "jwt-id-1", "exp" => 1.hour.from_now.to_i}
      payload2 = {"jti" => "jwt-id-2", "exp" => 2.hours.from_now.to_i}

      described_class.revoke_jwt(payload1, user)
      described_class.revoke_jwt(payload2, user)

      expect(described_class.jwt_revoked?(payload1, user)).to be true
      expect(described_class.jwt_revoked?(payload2, user)).to be true
    end
  end

  describe "database operations" do
    it "creates valid denylist entries" do
      entry = described_class.create!(jti: "test-jti", exp: 1.hour.from_now)
      expect(entry).to be_persisted
      expect(entry.jti).to eq("test-jti")
    end

    it "handles cleanup of expired tokens" do
      # Create an expired token
      described_class.create!(
        jti: "expired-jti",
        exp: 1.hour.ago
      )

      # Create a valid token
      described_class.create!(
        jti: "valid-jti",
        exp: 1.hour.from_now
      )

      expect(described_class.count).to eq(2)

      # Note: Actual cleanup would be handled by a background job
      # This test just verifies the data structure supports it
      expect(described_class.where("exp < ?", Time.current).count).to eq(1)
      expect(described_class.where("exp >= ?", Time.current).count).to eq(1)
    end
  end

  describe "security considerations" do
    it "prevents duplicate jti entries" do
      jti = "duplicate-test-jti"
      exp_time = 1.hour.from_now

      described_class.create!(jti: jti, exp: exp_time)

      expect {
        described_class.create!(jti: jti, exp: exp_time)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "handles edge case payloads gracefully" do
      # Test with minimal payload
      minimal_payload = {"jti" => "minimal-jwt"}
      expect { described_class.jwt_revoked?(minimal_payload, user) }.not_to raise_error

      # Test with nil payload
      expect { described_class.jwt_revoked?(nil, user) }.not_to raise_error

      # Test with empty payload
      expect { described_class.jwt_revoked?({}, user) }.not_to raise_error
    end
  end
end
