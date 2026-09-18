# frozen_string_literal: true

module DiscountStackingCompatibilities
  class DestroyService
    def initialize(discount:, compatible_discount:)
      @discount = discount
      @compatible_discount = compatible_discount
    end

    def call
      Discount.db.transaction do
        DiscountStackingCompatibility.where(discount_id: @discount.id, compatible_discount_id: @compatible_discount.id).delete
        DiscountStackingCompatibility.where(discount_id: @compatible_discount.id, compatible_discount_id: @discount.id).delete
      end
    end
  end
end
