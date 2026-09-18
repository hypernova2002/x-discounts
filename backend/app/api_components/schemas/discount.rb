# frozen_string_literal: true

module Schemas
  class Discount
    include OpenapiRuby::Components::Base

    schema(
      type: :object,
      properties: {
        id: { type: :string, readOnly: true },
        key: { type: :string, description: "Unique, developer-supplied identifier (per project)" },
        kind: { type: :string, enum: %w[promotion coupon] },
        name: { type: :string },
        stackable: { type: :boolean },
        eligibility_condition: ConditionNode,
        promotion: { anyOf: [Promotion, { type: :null }] },
        coupon: { anyOf: [Coupon, { type: :null }] },
        effects: { type: :array, items: DiscountEffect },
        max_redemptions: { type: :integer, nullable: true },
        max_redemptions_per_customer: { type: :integer, nullable: true },
        max_redemptions_per_day: { type: :integer, nullable: true },
        max_redemption_amount: { type: :number, nullable: true, description: "Total across the discount's whole lifetime" },
        max_redemption_amount_per_day: { type: :number, nullable: true },
        max_redemption_amount_per_customer: { type: :number, nullable: true },
        created_at: { type: :string, format: "date-time", readOnly: true },
        updated_at: { type: :string, format: "date-time", readOnly: true }
      }
    )
  end
end
