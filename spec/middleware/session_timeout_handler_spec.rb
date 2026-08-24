# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionTimeoutHandler do
  subject(:middleware) { described_class.new(downstream) }

  let(:downstream) { ->(_env) { [200, {"Content-Type" => "application/json"}, ["{}"]] } }

  def token(exp:)
    Warden::JWTAuth::TokenEncoder.new.call(
      "sub" => SecureRandom.uuid,
      "jti" => SecureRandom.uuid,
      "exp" => exp.to_i
    )
  end

  def env_for(path, token = nil)
    {"PATH_INFO" => path}.tap do |env|
      env["HTTP_AUTHORIZATION"] = "Bearer #{token}" if token
    end
  end

  describe "expired API sessions" do
    # Regression: the middleware decoded with credentials.secret_key_base while
    # Devise signs with Rails.application.secret_key_base. Credentials carry no
    # secret_key_base here, so every decode raised and was swallowed by the
    # JWT::DecodeError rescue, letting expired tokens through with a 200.
    it "rejects a token that has already expired" do
      status, _headers, body = middleware.call(env_for("/api/v1/cases", token(exp: 1.minute.ago)))

      expect(status).to eq(401)
      expect(JSON.parse(body.first)).to eq("error" => "Session expired")
    end

    it "decodes with the same secret Devise signs with" do
      expect(Rails.application.secret_key_base).to be_present

      status, = middleware.call(env_for("/api/v1/cases", token(exp: 10.minutes.from_now)))

      expect(status).to eq(200)
    end
  end

  describe "requests it must not intercept" do
    it "passes through non-API paths even with an expired token" do
      status, = middleware.call(env_for("/dashboard", token(exp: 1.minute.ago)))

      expect(status).to eq(200)
    end

    it "passes through API requests with no Authorization header" do
      status, = middleware.call(env_for("/api/v1/cases"))

      expect(status).to eq(200)
    end

    it "passes through an unparseable token rather than raising" do
      status, = middleware.call(env_for("/api/v1/cases", "not-a-jwt"))

      expect(status).to eq(200)
    end
  end
end
