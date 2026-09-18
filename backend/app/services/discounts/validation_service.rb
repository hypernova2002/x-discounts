# frozen_string_literal: true

module Discounts
  # Computes which of a project's discounts currently apply to a cart/customer, and
  # what they're worth. Read-only — doesn't create or touch a Redemption; that's the
  # separate redeem step. Amount-based usage limits are checked here using each
  # discount's actual candidate amount (see UsageLimitChecker), so this already avoids
  # the single-request overshoot; it does NOT lock anything, so a concurrent redeem can
  # still race past what this reported — RedeemService does the authoritative,
  # locked re-check right before persisting.
  #
  # Every individually-eligible promotion/coupon is gathered as a candidate first,
  # then StackingResolver decides which combination actually survives (respecting
  # `stackable` and discount_stacking_compatibilities) — only the accepted ones make
  # it into applicable_discounts. Loyalty discounts skip all of this and always
  # combine, same as before; stacking is about competing price reductions, and
  # earning points isn't one.
  class ValidationService
    def initialize(project:, cart:, line_items:, customer:, coupon_codes: [], as_of: nil, redeem_points: 0)
      @project = project
      @cart = cart.to_h.with_indifferent_access
      @line_items = line_items.map { |li| li.to_h.with_indifferent_access }
      @customer = customer.to_h.with_indifferent_access
      @coupon_codes = Array(coupon_codes).map(&:presence).compact
      @redeem_points = redeem_points.to_i
      @now = parse_as_of(as_of)
      @customer_record = lookup_customer_record
      @membership_tier = @customer_record&.membership_tier
    end

    def call
      candidates = []
      loyalty_results = []
      discounts = @project.discounts_dataset.where(enabled: true).eager(:campaign).all
      discounts.each do |discount|
        case discount.kind
        when "promotion" then add_promotion_candidate(discount, candidates)
        when "loyalty" then evaluate_loyalty(discount, loyalty_results)
        end
      end

      coupon_discount_ids = discounts.select { |d| d.kind == "coupon" }.map(&:id)
      coupon_entries = @coupon_codes.map do |code|
        coupon_code = find_coupon_code(coupon_discount_ids, code)
        coupon_code ? add_coupon_candidate(coupon_code.discount, code, candidates, coupon_code) : { code: code, reason: "not found" }
      end

      accepted = StackingResolver.resolve(candidates)
      accepted_discount_ids = accepted.map { |c| c[:discount].public_id }.to_set
      applicable = accepted.flat_map { |c| c[:results] }

      coupons = coupon_entries.map { |entry| build_coupon_result(entry, accepted_discount_ids) }

      {
        applicable_discounts: applicable,
        total_amount_off: applicable.sum { |a| a[:amount_off] || 0 }.round(2),
        coupons: coupons,
        loyalty_points: compute_loyalty_points(loyalty_results),
        points_redemption: compute_points_redemption(applicable)
      }
    end

    private

    def parse_as_of(as_of)
      return Time.now.utc if as_of.blank?

      Time.parse(as_of).utc
    rescue ArgumentError, TypeError
      raise ValidationError.new(details: [{ field: "as_of", message: "is not a valid time" }])
    end

    def evaluator(line_item: nil)
      ConditionEvaluator.new(cart: @cart, customer: @customer, line_item: line_item, line_items: @line_items, membership_tier: @membership_tier)
    end

    # Looked up once from the persisted Customer (by external_id), never trusted from
    # the submitted @customer hash — used for both the membership tier (see
    # ConditionEvaluator) and the points balance below, neither of which a client can
    # spoof by just submitting values in the request. A brand-new or not-yet-created
    # customer (or one with no external_id) simply has no tier and no balance yet.
    def lookup_customer_record
      external_id = @customer[:external_id].presence
      return nil unless external_id

      Customer.first(project_id: @project.id, external_id: external_id)
    end

    # @now honors as_of, so a preview can show what the balance would be at a
    # simulated time (e.g. after some lots have expired) — RedeemService always
    # re-checks this against the real clock, never a simulated one.
    def customer_points_balance
      return 0 unless @customer_record

      @customer_record.loyalty_points_balance(now: @now)
    end

    # 1 point = 1 currency unit, applied only after every merchant discount — so it
    # tops up whatever's left to pay, never turns the order negative, and never exceeds
    # what was actually requested or the customer's actual balance. RedeemService
    # re-does this exact computation under a lock on the customer row before persisting.
    def compute_points_redemption(applicable)
      balance = customer_points_balance
      discount_so_far = applicable.sum { |a| a[:amount_off] || 0 }
      remaining_payable = [cart_total - discount_so_far, 0].max
      applied = [@redeem_points, balance, remaining_payable.floor].min
      applied = 0 if applied.negative?

      { requested: @redeem_points, applied: applied, amount_off: applied, balance: balance }
    end

    def limit_checker(discount)
      UsageLimitChecker.new(discount: discount, customer: @customer, project: @project, now: @now)
    end

    # Shared by promotion and loyalty discounts — both store the same active_from/
    # active_until shape in kind_config. active_from is required at creation (see
    # PromotionRequest/LoyaltyRequest), so a nil here means corrupted/pre-validation
    # data rather than "no restriction" — fail closed (never active) rather than
    # crash the whole validate/redeem call over one broken discount.
    def active?(discount)
      return false unless discount.active_from

      discount.active_from <= @now && (discount.active_until.nil? || @now <= discount.active_until)
    end

    def add_promotion_candidate(discount, candidates)
      return unless discount.campaign.active?(@now)
      return unless active?(discount)
      return unless evaluator.evaluate(discount.eligibility_condition)

      results = evaluate_effects(discount)
      candidate_amount = results.sum { |r| r[:amount_off] || 0 }
      return unless limit_checker(discount).ok?(candidate_amount: candidate_amount)

      candidates << { discount: discount, results: results, value: candidate_value(results) }
    end

    # Collects both point-earning results (points:) and multiplier results (multiplier:)
    # from every eligible loyalty discount — compute_loyalty_points below combines them:
    # sum the earning ones, then multiply by the product of the multiplier ones. A
    # multiplier-only discount has no points of its own, so its candidate_amount for
    # usage-limit purposes is 0 — its own max_redemptions (a count) still applies.
    def evaluate_loyalty(discount, loyalty_results)
      return unless discount.campaign.active?(@now)
      return unless active?(discount)
      return unless evaluator.evaluate(discount.eligibility_condition)

      results = evaluate_loyalty_effects(discount)
      return if results.empty?

      candidate_points = results.sum { |r| r[:points] || 0 }
      return unless limit_checker(discount).ok?(candidate_amount: candidate_points)

      loyalty_results.concat(results)
    end

    # Among every coupon_code row matching this string, only one belonging to a
    # currently-reserving discount should ever exist (GenerateService blocks creating
    # a colliding one) — but this filters defensively rather than just taking the
    # first row, in case that invariant is ever violated by a race.
    # Codes are unique per project, permanently (DB-enforced) — at most one row can
    # ever match, so this is a direct lookup, not a "which one is actually still
    # active" filter.
    def find_coupon_code(coupon_discount_ids, code)
      return nil if coupon_discount_ids.empty?

      CouponCode.where(project_id: @project.id, code: code, discount_id: coupon_discount_ids).first
    end

    # Doesn't decide valid/invalid yet — that depends on whether this discount survives
    # StackingResolver, which needs every candidate gathered first. Returns either
    # {code:, reason:} (already known to be ungrantable) or {code:, candidate:}
    # (eligible so far, pending the resolver's call); build_coupon_result below turns
    # this into the actual response after resolution.
    def add_coupon_candidate(discount, code, candidates, coupon_code)
      reason = coupon_gate_reason(discount)
      return { code: code, reason: reason } if reason

      if coupon_code.customer_id && coupon_code.customer_id != @customer_record&.id
        return { code: code, reason: "not assigned to this customer" }
      end
      return { code: code, reason: "already redeemed" } if coupon_code.remaining_redemptions <= 0

      results = evaluator.evaluate(discount.eligibility_condition) ? evaluate_effects(discount, coupon_code: coupon_code) : []
      return { code: code, reason: "not eligible" } if results.empty?

      candidate_amount = results.sum { |r| r[:amount_off] || 0 }
      reason = limit_checker(discount).reason(candidate_amount: candidate_amount)
      return { code: code, reason: reason } if reason

      candidate = { discount: discount, results: results, value: candidate_value(results) }
      candidates << candidate
      { code: code, candidate: candidate }
    end

    def build_coupon_result(entry, accepted_discount_ids)
      return { code: entry[:code], valid: false, reason: entry[:reason], discounts: [] } unless entry[:candidate]

      candidate = entry[:candidate]
      unless accepted_discount_ids.include?(candidate[:discount].public_id)
        return { code: entry[:code], valid: false, reason: "conflicts with another applied discount", discounts: [] }
      end

      { code: entry[:code], valid: true, reason: nil, discounts: candidate[:results] }
    end

    def coupon_gate_reason(discount)
      return "campaign inactive" unless discount.campaign.active?(@now)
      return "not yet valid" if discount.valid_from && @now < discount.valid_from
      return "expired" if discount.valid_until && @now > discount.valid_until

      nil
    end

    def evaluate_effects(discount, coupon_code: nil)
      discount.discount_effects.flat_map do |effect|
        case effect.scope
        when "cart" then evaluate_cart_effect(discount, effect, coupon_code)
        when "line_item" then evaluate_line_item_effect(discount, effect, coupon_code)
        else []
        end
      end
    end

    def evaluate_cart_effect(discount, effect, coupon_code)
      return [] unless evaluator.evaluate(effect.target_condition)

      compute_effect(discount, effect, base_amount: cart_total, coupon_code: coupon_code)
    end

    def evaluate_line_item_effect(discount, effect, coupon_code)
      @line_items.each_with_object([]) do |line_item, results|
        next unless evaluator(line_item: line_item).evaluate(effect.target_condition)

        results.concat(compute_effect(discount, effect, base_amount: line_item_amount(line_item), line_item: line_item, coupon_code: coupon_code))
      end
    end

    def compute_effect(discount, effect, base_amount:, line_item: nil, coupon_code: nil)
      config = effect.config.to_h.stringify_keys
      sku = line_item && line_item[:sku]

      case effect.effect_type
      when "percentage_off"
        [discount_result(discount, effect, amount_off: (base_amount * config["percentage"].to_f / 100.0).round(2), sku: sku, coupon_code: coupon_code)]
      when "fixed_amount_off"
        [discount_result(discount, effect, amount_off: config["amount"].to_f.round(2), sku: sku, coupon_code: coupon_code)]
      when "free_item"
        compute_free_item(discount, effect, config, coupon_code)
      else
        []
      end
    end

    def evaluate_loyalty_effects(discount)
      discount.discount_effects.flat_map do |effect|
        case effect.scope
        when "cart" then evaluate_loyalty_cart_effect(discount, effect)
        when "line_item" then evaluate_loyalty_line_item_effect(discount, effect)
        else []
        end
      end
    end

    def evaluate_loyalty_cart_effect(discount, effect)
      return [] unless evaluator.evaluate(effect.target_condition)

      compute_loyalty_effect(discount, effect, base_amount: cart_total)
    end

    def evaluate_loyalty_line_item_effect(discount, effect)
      @line_items.each_with_object([]) do |line_item, results|
        next unless evaluator(line_item: line_item).evaluate(effect.target_condition)

        results.concat(compute_loyalty_effect(discount, effect, base_amount: line_item_amount(line_item), line_item: line_item))
      end
    end

    def compute_loyalty_effect(discount, effect, base_amount:, line_item: nil)
      config = effect.config.to_h.stringify_keys

      case effect.effect_type
      when "points_per_currency"
        [loyalty_result(discount, effect, points: (base_amount * config["rate"].to_f).round)]
      when "points_flat"
        [loyalty_result(discount, effect, points: config["points"].to_i)]
      when "points_per_item"
        return [] unless line_item

        [loyalty_result(discount, effect, points: line_item[:quantity].to_i * config["points_per_item"].to_i)]
      when "points_multiplier"
        [loyalty_result(discount, effect, multiplier: config["multiplier"].to_f)]
      else
        []
      end
    end

    def loyalty_result(discount, effect, points: nil, multiplier: nil)
      {
        discount_id: discount.public_id,
        kind: discount.kind,
        key: discount.key,
        name: discount.name,
        effect_type: effect.effect_type,
        points: points,
        multiplier: multiplier
      }.compact
    end

    # Sums every base-earning result, then multiplies by the product of every
    # points_multiplier result on the order (1.0 if none applied) — the "2x points when
    # two campaigns run together" mechanic. total_points is what actually gets awarded;
    # base_points/multiplier/breakdown are exposed so the caller can show how it adds up.
    def compute_loyalty_points(loyalty_results)
      base_points = loyalty_results.sum { |r| r[:points] || 0 }
      multiplier = loyalty_results.select { |r| r[:multiplier] }.reduce(1.0) { |acc, r| acc * r[:multiplier] }

      {
        total_points: (base_points * multiplier).round,
        base_points: base_points,
        multiplier: multiplier,
        breakdown: loyalty_results
      }
    end

    def compute_free_item(discount, effect, config, coupon_code)
      buy_quantity_required = config["buy_quantity"].to_i
      buy_quantity_total = @line_items.select { |li| evaluator(line_item: li).evaluate(config["buy_condition"]) }
                                       .sum { |li| li[:quantity].to_i }
      return [] if buy_quantity_total < buy_quantity_required

      get_matches = @line_items.select { |li| evaluator(line_item: li).evaluate(config["get_condition"]) }
      return [] if get_matches.empty?

      sets = config["repeatable"] ? buy_quantity_total / buy_quantity_required : 1
      target = get_matches.first
      free_quantity = [sets * config["get_quantity"].to_i, target[:quantity].to_i].min

      [discount_result(discount, effect, free_items: [{ sku: target[:sku], quantity: free_quantity }], coupon_code: coupon_code)]
    end

    def discount_result(discount, effect, amount_off: nil, free_items: nil, sku: nil, coupon_code: nil)
      {
        discount_id: discount.public_id,
        kind: discount.kind,
        key: discount.key,
        name: discount.name,
        effect_type: effect.effect_type,
        amount_off: amount_off,
        free_items: free_items,
        sku: sku,
        coupon_code_id: coupon_code&.public_id
      }.compact
    end

    # A free_item result has no amount_off of its own, but it's still a real dollar
    # saving — valued at the line item's own unit_price so it compares fairly against
    # amount_off results when StackingResolver picks the highest-value combination.
    def candidate_value(results)
      results.sum do |r|
        next r[:amount_off] if r[:amount_off]
        next free_items_value(r[:free_items]) if r[:free_items]

        0
      end
    end

    def free_items_value(free_items)
      free_items.sum do |fi|
        line_item = @line_items.find { |li| li[:sku] == fi[:sku] }
        line_item ? fi[:quantity] * line_item[:unit_price].to_f : 0
      end
    end

    def cart_total
      @line_items.sum { |li| line_item_amount(li) }
    end

    def line_item_amount(line_item)
      line_item[:quantity].to_f * line_item[:unit_price].to_f
    end
  end
end
