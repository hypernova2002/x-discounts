# frozen_string_literal: true

module Customers
  # Merges everything that's happened for a customer — orders, gift shop
  # redemptions, and their current membership tier entry — into one
  # chronologically-sorted feed, most recent first. Order-based points
  # earned/redeemed are shown as part of the order event they belong to rather
  # than as separate entries (that's what they already are structurally).
  class ActivityFeedService
    LIMIT = 100

    def initialize(customer:)
      @customer = customer
    end

    def call
      events = order_events + gift_shop_events + membership_events
      events.sort_by { |e| e[:occurred_at] }.reverse.first(LIMIT)
    end

    private

    def order_events
      @customer.orders_dataset.order(Sequel.desc(:created_at)).all.map do |order|
        {
          type: "order",
          occurred_at: order.created_at,
          order_id: order.public_id,
          total_amount: order.total_amount.to_s,
          total_discount_amount: order.total_discount_amount.to_s,
          total_points_earned: order.total_points_earned,
          total_points_redeemed: order.total_points_redeemed
        }
      end
    end

    def gift_shop_events
      @customer.gift_shop_redemptions_dataset.order(Sequel.desc(:redeemed_at)).all.map do |redemption|
        {
          type: "gift_shop_redemption",
          occurred_at: redemption.redeemed_at,
          item_name: redemption.item_name,
          quantity: redemption.quantity,
          points_spent: redemption.points_spent
        }
      end
    end

    def membership_events
      return [] unless @customer.membership_tier && @customer.membership_tier_entered_at

      [{
        type: "membership",
        occurred_at: @customer.membership_tier_entered_at,
        tier_name: @customer.membership_tier.name,
        scheme_name: @customer.membership_tier.membership_scheme.name
      }]
    end
  end
end
