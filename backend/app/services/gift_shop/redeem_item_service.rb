# frozen_string_literal: true

module GiftShop
  # Exchanges points for a gift shop item — the second of the two loyalty-points
  # redemption paths (the first being Discounts::RedeemService's order-price
  # reduction). Both ultimately spend through the same Customer#consume_loyalty_points!
  # ledger, so a customer's balance is always consistent regardless of which path
  # they used.
  #
  # Customer then item are locked in that fixed order (matching
  # Discounts::RedeemService's customer-before-discounts ordering) so two concurrent
  # redemptions — of the same item, by the same customer, or any combination — can
  # never deadlock against each other, and neither the customer's balance nor the
  # item's stock can be oversold by a race.
  class RedeemItemService
    def initialize(project:, item:, customer_external_id:, quantity: 1)
      @project = project
      @item = item
      @customer_external_id = customer_external_id
      @quantity = quantity.to_i
    end

    def call
      customer = find_customer!
      redemption = nil

      GiftShopItem.db.transaction do
        customer.lock!
        item = @item.lock!

        points_needed = item.points_cost * @quantity
        balance = customer.loyalty_points_balance
        if balance < points_needed
          raise ValidationError.new(
            details: [{ field: "quantity", message: "customer only has #{balance} points, needs #{points_needed}" }]
          )
        end

        if item.stock && item.stock < @quantity
          raise ValidationError.new(details: [{ field: "quantity", message: "only #{item.stock} left in stock" }])
        end

        redemption = customer.add_gift_shop_redemption(
          gift_shop_item: item,
          item_name: item.name,
          quantity: @quantity,
          points_spent: points_needed,
          redeemed_at: Time.now.utc
        )
        customer.consume_loyalty_points!(points_needed, spend_ref: redemption)
        item.update(stock: item.stock - @quantity) if item.stock
      end

      redemption
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end

    private

    def find_customer!
      raise ValidationError.new(details: [{ field: "quantity", message: "must be a positive number" }]) unless @quantity.positive?

      customer = Customer.first(project_id: @project.id, external_id: @customer_external_id)
      unless customer
        raise ValidationError.new(details: [{ field: "customer_external_id", message: "does not refer to an existing customer" }])
      end

      customer
    end
  end
end
