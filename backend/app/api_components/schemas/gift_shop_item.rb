# frozen_string_literal: true

module Schemas
  class GiftShopItem
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        name: { type: :string },
        description: { type: :string, nullable: true },
        points_cost: { type: :integer },
        stock: { type: :integer, nullable: true },
        enabled: { type: :boolean },
        created_at: { type: :string, format: "date-time", readOnly: true },
        updated_at: { type: :string, format: "date-time", readOnly: true },
        in_stock: { type: :boolean, readOnly: true },
        photo_url: { type: :string, nullable: true, readOnly: true }
      }
    )
  end
end
