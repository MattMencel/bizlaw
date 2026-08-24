# frozen_string_literal: true

class SessionTimeoutHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    # Checked before @app.call: a 401 issued after the fact would still leave
    # the downstream action's side effects committed.
    if api_request?(env) && authenticated_request?(env)
      token = extract_jwt_token(env)

      if token && token_expired?(token)
        return [401, {"Content-Type" => "application/json"}, [{error: "Session expired"}.to_json]]
      end
    end

    @app.call(env)
  end

  private

  def api_request?(env)
    env["PATH_INFO"].start_with?("/api/")
  end

  def authenticated_request?(env)
    env["HTTP_AUTHORIZATION"].present?
  end

  def extract_jwt_token(env)
    return nil unless env["HTTP_AUTHORIZATION"]

    env["HTTP_AUTHORIZATION"].split(" ").last
  end

  # JWT.decode verifies exp itself and raises ExpiredSignature, coercing the
  # claim with to_i on the way. Comparing payload["exp"] by hand here duplicated
  # that and raised ArgumentError whenever the claim was not already an Integer.
  def token_expired?(token)
    JWT.decode(token, Rails.application.secret_key_base)
    false
  rescue JWT::ExpiredSignature
    true
  rescue JWT::DecodeError
    false
  end
end
