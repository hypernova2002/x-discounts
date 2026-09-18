# frozen_string_literal: true

module SecuritySchemes
  # Bearer <token>, where token is either an xdk_... API key (project+role fixed
  # at issuance) or a sess_... session token (role resolved live per X-Project-Id).
  class BearerAuth
    include OpenapiRuby::Components::Base
    component_type :securitySchemes

    schema(
      type: :http,
      scheme: :bearer
    )
  end
end
