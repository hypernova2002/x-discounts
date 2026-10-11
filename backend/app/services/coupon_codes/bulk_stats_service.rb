# frozen_string_literal: true

module CouponCodes
  # Bulk form of CouponCode#redemption_count — given a batch of CouponCode rows
  # (each needs :id loaded), returns a { coupon_code_id => redemption_count }
  # map in 2 queries total, instead of 2 queries per code.
  class BulkStatsService
    Result = Struct.new(:redemption_counts, keyword_init: true)

    def initialize(codes)
      @codes = codes
    end

    def call
      Result.new(redemption_counts: redemption_counts)
    end

    private

    def redemption_counts
      code_ids = @codes.map(&:id)
      return {} if code_ids.empty?

      order_discounts = OrderDiscount
                         .join(:redemptions, id: :redemption_id)
                         .where(Sequel[:redemptions][:coupon_code_id] => code_ids)
                         .select(Sequel[:order_discounts][:id], Sequel[:order_discounts][:kind], Sequel[:redemptions][:coupon_code_id].as(:coupon_code_id))
                         .all
      refunded_ids = RefundedOrderDiscounts.ids_among(order_discounts)

      order_discounts.reject { |od| refunded_ids.include?(od.id) }.group_by { |od| od[:coupon_code_id] }.transform_values(&:count)
    end
  end
end
