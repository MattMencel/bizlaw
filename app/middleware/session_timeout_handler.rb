# frozen_string_literal: true

class SessionTimeoutHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    if api_request?(env) && authenticated_request?(env)
      token = extract_jwt_token(env)

      if token && token_expired?(token)
        return [ 401, { "Content-Type" => "application/json" }, [ { error: "Session expired" }.to_json ] ]
      end
    end

    [ status, headers, response ]
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

  def token_expired?(token)
    JWT.decode(token, Rails.application.credentials.secret_key_base).first["exp"] < Time.now.to_i
  rescue JWT::ExpiredSignature
    true
  rescue JWT::DecodeError
    false
  end
end
