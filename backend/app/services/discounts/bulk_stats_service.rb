# frozen_string_literal: true

module Discounts
  # Bulk, includes=-driven replacement for the per-row queries DiscountResource
  # would otherwise run for `redemption_count`/`coupon_code_stats` on a list of
  # discounts. Each lookup costs a small constant number of queries regardless
  # of how many discounts (or coupon codes) are in the batch.
  class BulkStatsService
    Result = Struct.new(:redemption_counts, :coupon_code_stats, :discount_kinds_by_campaign, keyword_init: true)

    def initialize(discounts)
      @discounts = discounts
    end

    def call
      Result.new(
        redemption_counts: redemption_counts,
        coupon_code_stats: coupon_code_stats,
        discount_kinds_by_campaign: discount_kinds_by_campaign
      )
    end

    private

    def discount_ids
      @discount_ids ||= @discounts.map(&:id)
    end

    def redemption_counts
      order_discounts = OrderDiscount.where(discount_id: discount_ids).select(:id, :discount_id, :kind).all
      refunded_ids = RefundedOrderDiscounts.ids_among(order_discounts)

      order_discounts.reject { |od| refunded_ids.include?(od.id) }.group_by(&:discount_id).transform_values(&:count)
    end

    def coupon_code_stats
      coupon_discount_ids = @discounts.select { |d| d.kind == "coupon" }.map(&:id)
      return {} if coupon_discount_ids.empty?

      codes = CouponCode.where(discount_id: coupon_discount_ids).select(:id, :discount_id, :max_redemptions).all
      redemption_counts_by_code = CouponCodes::BulkStatsService.new(codes).call.redemption_counts

      codes.group_by(&:discount_id).transform_values do |discount_codes|
        available = discount_codes.count { |c| c.max_redemptions - redemption_counts_by_code.fetch(c.id, 0) > 0 }
        { total: discount_codes.size, available: available }
      end
    end

    def discount_kinds_by_campaign
      campaign_ids = @discounts.map(&:campaign_id).compact.uniq
      Discount.kinds_by_campaign(campaign_ids)
    end
  end
end
