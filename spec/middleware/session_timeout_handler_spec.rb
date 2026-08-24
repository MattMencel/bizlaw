# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionTimeoutHandler do
  subject(:middleware) { described_class.new(downstream) }

  let(:calls) { [] }
  let(:downstream) do
    lambda do |env|
      calls << env["PATH_INFO"]
      [200, {"Content-Type" => "application/json"}, ["{}"]]
    end
  end

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

    # Regression: the expiry check used to run after @app.call, so a
    # state-changing request committed its side effects and only then had the
    # response swapped for a 401.
    it "does not invoke the downstream app for an expired token" do
      middleware.call(env_for("/api/v1/cases", token(exp: 1.minute.ago)))

      expect(calls).to be_empty
    end

    it "decodes with the same secret Devise signs with" do
      expect(Rails.application.secret_key_base).to be_present

      status, = middleware.call(env_for("/api/v1/cases", token(exp: 10.minutes.from_now)))

      expect(status).to eq(200)
    end
  end

  describe "non-integer exp claims" do
    # warden-jwt_auth built exp as Time.now.to_i + expiration_time; with a
    # Duration configured that produced a string claim, and the old hand-rolled
    # comparison raised ArgumentError on every authenticated API request.
    # ActiveSupport::Duration reports itself as Numeric, so JWT.encode accepts it
    # and only JSON serialization turns the claim into a string. Building the
    # token any other way cannot reproduce this - jwt 3 rejects a String exp
    # outright with JWT::InvalidPayload.
    def token_with_duration_exp(seconds_from_now)
      JWT.encode(
        {"sub" => SecureRandom.uuid, "jti" => SecureRandom.uuid,
         "exp" => Time.now.to_i + seconds_from_now.seconds},
        Rails.application.secret_key_base,
        "HS256"
      )
    end

    it "treats a stringly-typed expired claim as expired" do
      status, = middleware.call(env_for("/api/v1/cases", token_with_duration_exp(-60)))

      expect(status).to eq(401)
    end

    it "lets a stringly-typed live claim through without raising" do
      status, = middleware.call(env_for("/api/v1/cases", token_with_duration_exp(600)))

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
