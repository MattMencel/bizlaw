# frozen_string_literal: true

require "rswag/ui"

Rswag::Ui.configure do |c|
  # List the Swagger endpoints that you want to be documented through the
  # swagger-ui. The first parameter is the path (absolute or relative to the UI
  # host) to the corresponding endpoint and the second is a title that will be
  # displayed in the document selector.
  # NOTE: If you're using rswag-api to serve API descriptions, you'll need to ensure
  # that it's configured to serve Swagger from the same folder

  c.openapi_endpoint "/api-docs/v1/swagger.yaml", "API V1 Docs"

  # Add Basic Auth in case your API is private
  # c.basic_auth_enabled = true
  # c.basic_auth_credentials 'username', 'password'
end
