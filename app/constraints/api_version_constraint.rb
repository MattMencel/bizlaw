# frozen_string_literal: true

class ApiVersionConstraint
  def initialize(version:, default: false)
    @version = version
    @default = default
  end

  def matches?(request)
    return true if @default

    accept_header = request.headers["Accept"]
    # Check version in Accept header (e.g., application/vnd.business-law.v1+json)
    header_version = accept_header&.match(/application\/vnd\.business-law\.v(\d+)\+json/)&.[](1)&.to_i
    # Check version in URL path (e.g., /api/v1)
    path_version = request.path.match(/\/api\/v(\d+)/)&.[](1)&.to_i

    # Return true if either header or path version matches
    (header_version || path_version) == @version
  end
end
