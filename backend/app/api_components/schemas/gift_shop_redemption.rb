# frozen_string_literal: true

module Schemas
  class GiftShopRedemption
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        item_name: { type: :string },
        quantity: { type: :integer },
        points_spent: { type: :integer },
        redeemed_at: { type: :string, format: "date-time" },
        item_id: { type: :string, nullable: true, readOnly: true },
        customer_id: { type: :string, readOnly: true }
      }
    )
  end
end
