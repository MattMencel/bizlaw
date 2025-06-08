# frozen_string_literal: true

class ApiVersionHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    if api_request?(env)
      headers["X-API-Version"] = "1.0"
      headers["X-API-Deprecated"] = "false"
    end

    [ status, headers, response ]
  end

  private

  def api_request?(env)
    env["PATH_INFO"].start_with?("/api/")
  end
end
