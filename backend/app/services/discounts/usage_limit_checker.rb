# frozen_string_literal: true

module Discounts
  # Single source of truth for "is this discount within its usage/spend limits" — used
  # both for the initial, unlocked evaluation in ValidationService and the final,
  # locked, authoritative re-check in RedeemService right before persisting an
  # OrderDiscount. All six limits are counted via OrderDiscount (not the coupon-only
  # Redemption table), so they work identically for promotions and coupons.
  #
  # Count-based limits (max_redemptions / _per_day / _per_customer) don't need the
  # candidate amount — every redemption always contributes exactly one, so "already at
  # or over the limit" is equivalent to "this one would push it over". Amount-based
  # limits vary per redemption, so they take the amount this evaluation would actually
  # add and check the prospective total, not just what's already committed — otherwise
  # spend can overshoot the cap by up to one redemption's amount before the next one
  # gets blocked.
  #
  # NOTE: when a discount is dropped for exceeding an amount-based limit, it's dropped
  # entirely rather than truncated to whatever budget remains — simplest rule, and the
  # only one that means the same thing for free_item (which can't be partially
  # granted). Revisit if some callers want truncation instead of all-or-nothing.
  class UsageLimitChecker
    def initialize(discount:, customer:, project:, now:)
      @discount = discount
      @customer = customer
      @project = project
      @now = now
    end

    def ok?(candidate_amount: 0)
      reason(candidate_amount: candidate_amount).nil?
    end

    def reason(candidate_amount: 0)
      return "redemption limit reached" if over_count_limit?
      return "per-customer redemption limit reached" if over_per_customer_count_limit?
      return "daily redemption limit reached" if over_per_day_count_limit?
      return "campaign redemption amount limit reached" if over_total_amount_limit?(candidate_amount)
      return "daily redemption amount limit reached" if over_per_day_amount_limit?(candidate_amount)
      return "per-customer redemption amount limit reached" if over_per_customer_amount_limit?(candidate_amount)

      nil
    end

    private

    # Refunded rows (any refund at all, not just a full one — see Refunds::CreateService
    # and OrderDiscount#refunded?) no longer count against usage limits, freeing up the
    # slot they used.
    def order_discounts
      base = OrderDiscount.where(discount_id: @discount.id)
      refunded_ids = base.all.select(&:refunded?).map(&:id)
      refunded_ids.empty? ? base : base.exclude(id: refunded_ids)
    end

    def order_discounts_today
      start_of_day = Time.utc(@now.year, @now.month, @now.day)
      order_discounts.where(created_at: start_of_day...(start_of_day + 24 * 60 * 60))
    end

    def customer_record
      return @customer_record if defined?(@customer_record)

      @customer_record = @customer[:external_id].present? ? Customer.first(project_id: @project.id, external_id: @customer[:external_id]) : nil
    end

    def customer_order_ids
      return @customer_order_ids if defined?(@customer_order_ids)

      @customer_order_ids = customer_record ? Order.where(customer_id: customer_record.id).select_map(:id) : []
    end

    def order_discounts_for_customer
      order_discounts.where(order_id: customer_order_ids)
    end

    def over_count_limit?
      @discount.max_redemptions && order_discounts.count >= @discount.max_redemptions
    end

    def over_per_customer_count_limit?
      return false unless @discount.max_redemptions_per_customer && customer_record

      order_discounts_for_customer.count >= @discount.max_redemptions_per_customer
    end

    def over_per_day_count_limit?
      @discount.max_redemptions_per_day && order_discounts_today.count >= @discount.max_redemptions_per_day
    end

    def over_total_amount_limit?(candidate_amount)
      return false unless @discount.max_redemption_amount

      order_discounts.sum(:amount_off).to_f + candidate_amount.to_f > @discount.max_redemption_amount
    end

    def over_per_day_amount_limit?(candidate_amount)
      return false unless @discount.max_redemption_amount_per_day

      order_discounts_today.sum(:amount_off).to_f + candidate_amount.to_f > @discount.max_redemption_amount_per_day
    end

    def over_per_customer_amount_limit?(candidate_amount)
      return false unless @discount.max_redemption_amount_per_customer && customer_record

      order_discounts_for_customer.sum(:amount_off).to_f + candidate_amount.to_f > @discount.max_redemption_amount_per_customer
    end
  end
end
