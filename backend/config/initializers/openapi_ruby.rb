# frozen_string_literal: true

OpenapiRuby.configure do |config|
  # Define your API schemas. Each key is a schema name, and can have its own
  # info, servers, and component scope.
  config.schemas = {
    public_api: {
      info: { title: "x-discounts API", version: "v1" },
      servers: [{ url: "/" }]
    }
  }

  # Where to find schema component classes
  config.component_paths = ["app/api_components"]

  # Our API is snake_case throughout (request and response bodies alike) — don't
  # camelize, or the generated docs would describe a shape the API doesn't return.
  config.camelize_keys = false

  # Generated schema output
  config.schema_output_dir = "openapi"
  config.schema_output_format = :yaml

  # Runtime request/response validation middleware
  # Options: :disabled, :enabled, :warn_only
  config.request_validation = :disabled
  config.response_validation = :disabled

  # Swagger UI at the engine's mount path (disabled by default).
  # When false, only the schema endpoints are served.
  config.ui_enabled = true
end
