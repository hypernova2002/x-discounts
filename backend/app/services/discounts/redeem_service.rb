# frozen_string_literal: true

module Discounts
  # Persists what ValidationService only computes: upserts the Customer, creates the
  # Order + its line items, and records an OrderDiscount per applicable discount
  # (plus a Redemption for coupon-kind ones — that's what actually counts against
  # max_redemptions going forward). An invalid submitted coupon code doesn't block
  # the order; it just contributes no discount, same as ValidationService reports it.
  #
  # ValidationService's check is unlocked and can go stale between two concurrent
  # redemptions of the same discount. Before actually persisting an OrderDiscount, this
  # locks that discount row (SELECT ... FOR UPDATE, via Sequel's #lock!) and re-runs the
  # same UsageLimitChecker against fresh data — any other transaction trying to redeem
  # the same discount blocks until this one commits, so the re-check sees a consistent
  # picture instead of racing. Discounts are locked in a fixed (id) order across every
  # call, which is what keeps two concurrent multi-discount redemptions from deadlocking
  # on each other.
  class RedeemService
    def initialize(project:, cart:, line_items:, customer:, coupon_codes: [], redeem_points: 0)
      @project = project
      @cart = cart
      @line_items = line_items.map { |li| li.to_h.with_indifferent_access }
      @customer_attrs = customer.to_h.with_indifferent_access
      @coupon_codes = coupon_codes
      @redeem_points = redeem_points.to_i
    end

    def call
      customer = Customers::CreateService.new(project: @project, attrs: @customer_attrs).call

      # No as_of here, deliberately — a real redemption always checks against the
      # real clock, never a client-supplied one (see DiscountValidationRequest#as_of).
      result = ValidationService.new(
        project: @project,
        cart: @cart,
        line_items: @line_items,
        customer: @customer_attrs,
        coupon_codes: @coupon_codes,
        redeem_points: @redeem_points
      ).call

      order = nil
      applied_discount_ids = []
      total_discount_amount = 0
      points_redeemed = 0
      Order.db.transaction do
        order = build_order(customer)
        create_line_items(order)

        # Locked before any discount, in a fixed order (customer, then discounts by
        # id) — so two concurrent orders can never deadlock against each other over
        # these rows, and this customer's balance can't be double-spent by a second
        # concurrent redemption.
        customer.lock!

        applied_discount_ids, total_discount_amount = create_order_discounts(order, result[:applicable_discounts])

        # Redeem existing balance before this order's own points are earned below —
        # a customer can't spend points from the same purchase that generated them.
        points_discount_amount = 0
        points_redeemed, points_discount_amount = apply_points_redemption(order, customer, total_discount_amount)
        total_discount_amount += points_discount_amount

        loyalty_applied_ids, = create_loyalty_discounts(order, customer, result[:loyalty_points][:breakdown])
        applied_discount_ids += loyalty_applied_ids

        order.update(total_discount_amount: total_discount_amount)

        # This order's totals (spend, points, order count) are now what a tier's
        # requirements would see — re-evaluate immediately so a qualifying purchase
        # promotes right away, without waiting for the periodic sweep.
        Memberships::EvaluateCustomerService.new(customer: customer).call
      end

      {
        order: order,
        coupons: adjust_coupon_results(result[:coupons], applied_discount_ids),
        points_redemption: { requested: @redeem_points, applied: points_redeemed, amount_off: points_redeemed }
      }
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end

    private

    def build_order(customer)
      order = Order.new(project: @project, customer: customer, total_amount: cart_total, total_discount_amount: 0)
      order.save
      order
    end

    def create_line_items(order)
      @line_items.each do |li|
        order.add_order_line_item(
          sku: li[:sku],
          quantity: li[:quantity].to_i,
          unit_price: li[:unit_price].to_f,
          metadata: li.except(:sku, :quantity, :unit_price).to_h
        )
      end
    end

    # Groups by discount so the re-check (and the lock) happens once per discount, not
    # once per effect — a discount with several line-item-scoped effects contributes
    # several entries to applicable_discounts but should only be gated once, using the
    # sum of what it's about to grant.
    # Returns [discount_public_ids_actually_applied, total_amount_actually_applied].
    def create_order_discounts(order, applicable_discounts)
      grouped = applicable_discounts.group_by { |a| a[:discount_id] }
      return [[], 0] if grouped.empty?

      locked_discounts = Discount.where(project_id: @project.id, public_id: grouped.keys).order(:id).all.map(&:lock!)

      applied_ids = []
      total = locked_discounts.sum do |discount|
        # Locks (and re-checks) any coupon_code involved before the discount-level
        # usage-limit check runs, so an entry riding a code that lost the race (e.g.
        # a single-use code someone else just redeemed) doesn't count toward the
        # amount this discount is about to grant.
        applied_entries = grouped[discount.public_id].select { |a| coupon_code_still_available?(a) }
        next 0 if applied_entries.empty?

        candidate_amount = applied_entries.sum { |a| a[:amount_off] || 0 }

        next 0 unless discount.campaign.active?

        checker = UsageLimitChecker.new(discount: discount, customer: @customer_attrs, project: @project, now: Time.now.utc)
        next 0 unless checker.ok?(candidate_amount: candidate_amount)

        applied_entries.each { |applied| create_order_discount(order, discount, applied) }
        applied_ids << discount.public_id
        candidate_amount
      end

      [applied_ids, total]
    end

    def coupon_code_still_available?(applied)
      return true unless applied[:coupon_code_id]

      coupon_code = CouponCode.first(public_id: applied[:coupon_code_id])&.lock!
      return false unless coupon_code

      coupon_code.remaining_redemptions.positive?
    end

    # Same lock-and-recheck discipline as create_order_discounts, but for loyalty
    # discounts. A discount's own points (pre-multiplier) and any multiplier discount are
    # both re-verified against usage limits independently, checked against each
    # discount's own raw (pre-multiplier) contribution — multiplying doesn't let a
    # discount grant more than its own limits allow, it just scales what survived.
    # Each surviving earning discount gets its own lot, sized post-multiplier and
    # expiring per *that* discount's own points_expire_after_days — so two discounts
    # with different expiration policies stacking under the same multiplier still each
    # expire on their own schedule.
    def create_loyalty_discounts(order, customer, breakdown)
      grouped = breakdown.group_by { |a| a[:discount_id] }
      return [[], 0] if grouped.empty?

      locked_discounts = Discount.where(project_id: @project.id, public_id: grouped.keys).order(:id).all.map(&:lock!)

      applied_ids = []
      surviving_earning = []
      order_discounts_by_discount_id = Hash.new { |h, k| h[k] = [] }
      multiplier = 1.0

      locked_discounts.each do |discount|
        applied_entries = grouped[discount.public_id]
        candidate_points = applied_entries.sum { |a| a[:points] || 0 }

        next unless discount.campaign.active?

        checker = UsageLimitChecker.new(discount: discount, customer: @customer_attrs, project: @project, now: Time.now.utc)
        next unless checker.ok?(candidate_amount: candidate_points)

        applied_entries.each { |applied| order_discounts_by_discount_id[discount.id] << create_order_discount(order, discount, applied) }
        applied_ids << discount.public_id
        surviving_earning << [discount, candidate_points] if candidate_points.positive?
        applied_entries.each { |a| multiplier *= a[:multiplier] if a[:multiplier] }
      end

      total_points = 0
      surviving_earning.each do |discount, candidate_points|
        lot_points = (candidate_points * multiplier).round
        next if lot_points <= 0

        lot = create_points_lot(order, customer, discount, lot_points)
        order_discounts_by_discount_id[discount.id].each { |od| od.update(loyalty_point_lot: lot) }
        total_points += lot_points
      end

      [applied_ids, total_points]
    end

    def create_points_lot(order, customer, discount, points)
      expire_days = discount.points_expire_after_days
      now = Time.now.utc
      customer.add_loyalty_point_lot(
        order: order,
        discount: discount,
        points: points,
        earned_at: now,
        expires_at: expire_days ? now + expire_days.days : nil,
        source: "order"
      )
    end

    # Re-does ValidationService's points-redemption computation against the customer
    # row already locked in #call, so it can't be double-spent by a second concurrent
    # redemption — capped to the requested amount, the actual (locked, fresh) balance,
    # and whatever's still owed after every other discount just applied.
    def apply_points_redemption(order, customer, discount_so_far)
      return [0, 0] if @redeem_points <= 0

      balance = customer.loyalty_points_balance
      remaining_payable = [cart_total - discount_so_far, 0].max
      points_to_redeem = [@redeem_points, balance, remaining_payable.floor].min
      return [0, 0] if points_to_redeem <= 0

      redemption = PointsRedemption.create(order: order, customer: customer, points_redeemed: points_to_redeem, amount_off: points_to_redeem)

      # customer is already locked in #call, which serializes every concurrent
      # spend/earn for them, so Customer#consume_loyalty_points! doesn't need its own lock.
      customer.consume_loyalty_points!(points_to_redeem, spend_ref: redemption)

      [points_to_redeem, points_to_redeem]
    end

    # A coupon can be reported valid by the unlocked ValidationService pass and still
    # lose the race to another concurrent redemption by the time the locked re-check
    # above runs — this catches that so the response never claims a coupon applied
    # when nothing was actually persisted for it.
    def adjust_coupon_results(coupon_results, applied_discount_ids)
      coupon_results.map do |coupon_result|
        next coupon_result unless coupon_result[:valid]

        discount_id = coupon_result[:discounts].first&.dig(:discount_id)
        next coupon_result if discount_id.nil? || applied_discount_ids.include?(discount_id)

        { code: coupon_result[:code], valid: false, reason: "redemption limit reached", discounts: [] }
      end
    end

    def create_order_discount(order, discount, applied)
      redemption = create_redemption(discount, order.customer_id, applied[:coupon_code_id]) if applied[:kind] == "coupon"

      order.add_order_discount(
        discount: discount,
        redemption: redemption,
        kind: applied[:kind],
        discount_key: applied[:key],
        discount_name: applied[:name],
        effect_type: applied[:effect_type],
        amount_off: applied[:amount_off],
        free_items: applied[:free_items],
        sku: applied[:sku]
      )
    end

    # coupon_code_still_available? already locked and re-verified this exact row
    # earlier in the same transaction, so no further check is needed here.
    def create_redemption(discount, customer_id, coupon_code_public_id)
      coupon_code = CouponCode.first(public_id: coupon_code_public_id)
      Redemption.create(discount: discount, customer_id: customer_id, coupon_code: coupon_code, redeemed_at: Time.now.utc)
    end

    def cart_total
      @line_items.sum { |li| li[:quantity].to_f * li[:unit_price].to_f }
    end
  end
end
