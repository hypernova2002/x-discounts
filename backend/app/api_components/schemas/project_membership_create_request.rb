# frozen_string_literal: true

module Schemas
  class ProjectMembershipCreateRequest
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      required: %w[user_id role],
      properties: {
        user_id: { type: :string },
        role: { type: :string, enum: %w[admin developer marketer viewer] }
      }
    )
  end
end
