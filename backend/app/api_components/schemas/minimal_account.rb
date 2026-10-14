# frozen_string_literal: true

module Schemas
  # Matches MinimalAccountResource — what /me returns for the current account.
  class MinimalAccount
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        name: { type: :string }
      }
    )
  end
end
