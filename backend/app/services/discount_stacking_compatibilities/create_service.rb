# frozen_string_literal: true

module DiscountStackingCompatibilities
  # Compatibility is inherently symmetric (if A can combine with B, B can combine
  # with A) — writes both directional rows atomically so StackingResolver's lookup
  # never has to check both directions itself.
  class CreateService
    def initialize(discount:, compatible_discount:)
      @discount = discount
      @compatible_discount = compatible_discount
    end

    def call
      if @discount.id == @compatible_discount.id
        raise ValidationError.new(details: [{ field: "compatible_discount_id", message: "cannot equal the discount itself" }])
      end

      Discount.db.transaction do
        DiscountStackingCompatibility.find_or_create(discount_id: @discount.id, compatible_discount_id: @compatible_discount.id)
        DiscountStackingCompatibility.find_or_create(discount_id: @compatible_discount.id, compatible_discount_id: @discount.id)
      end
    end
  end
end
