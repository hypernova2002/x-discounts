require "rails_helper"

RSpec.describe Discounts::ValidationService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }

  def validate(line_items:, cart: {}, customer: {}, coupon_codes: [], as_of: nil, redeem_points: 0)
    described_class.new(project: project, cart: cart, line_items: line_items, customer: customer,
                         coupon_codes: coupon_codes, as_of: as_of, redeem_points: redeem_points).call
  end

  def active_promotion(**attrs)
    create(:discount, project: project, campaign: campaign, kind: "promotion",
                       kind_config: { active_from: 1.year.ago.iso8601 }, **attrs)
  end

  def active_loyalty(**attrs)
    create(:discount, project: project, campaign: campaign, kind: "loyalty",
                       kind_config: { active_from: 1.year.ago.iso8601 }, **attrs)
  end

  let(:line_items) { [{ sku: "X", quantity: 1, unit_price: 100 }] }

  describe "effects" do
    it "applies percentage_off at cart scope" do
      discount = active_promotion
      create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })

      result = validate(line_items: line_items)
      expect(result[:total_amount_off]).to eq(10.0)
    end

    it "applies fixed_amount_off at cart scope" do
      discount = active_promotion
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items)
      expect(result[:total_amount_off]).to eq(5.0)
    end

    it "applies an effect at line_item scope only to matching line items, gated by target_condition" do
      discount = active_promotion
      create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "line_item", config: { percentage: 10 },
                                target_condition: { entity: "line_item", key: "sku", operator: "eq", value: "X" })

      items = [{ sku: "X", quantity: 1, unit_price: 100 }, { sku: "Y", quantity: 1, unit_price: 50 }]
      result = validate(line_items: items)
      expect(result[:total_amount_off]).to eq(10.0)
    end

    describe "free_item" do
      def free_item_discount(repeatable:)
        discount = active_promotion
        create(:discount_effect, discount: discount, effect_type: "free_item", scope: "cart",
                                  config: {
                                    buy_quantity: 2, get_quantity: 1, repeatable: repeatable,
                                    buy_condition: { entity: "line_item", key: "sku", operator: "eq", value: "A" },
                                    get_condition: { entity: "line_item", key: "sku", operator: "eq", value: "B" }
                                  })
        discount
      end

      it "grants nothing below the buy_quantity threshold" do
        free_item_discount(repeatable: false)
        items = [{ sku: "A", quantity: 1, unit_price: 10 }, { sku: "B", quantity: 5, unit_price: 5 }]
        result = validate(line_items: items)
        expect(result[:applicable_discounts]).to be_empty
      end

      it "grants nothing when no line item matches get_condition" do
        free_item_discount(repeatable: false)
        items = [{ sku: "A", quantity: 5, unit_price: 10 }]
        result = validate(line_items: items)
        expect(result[:applicable_discounts]).to be_empty
      end

      it "grants exactly one set when not repeatable, even if the buy condition is over-satisfied" do
        free_item_discount(repeatable: false)
        items = [{ sku: "A", quantity: 6, unit_price: 10 }, { sku: "B", quantity: 5, unit_price: 5 }]
        result = validate(line_items: items)
        expect(result[:applicable_discounts].first[:free_items]).to eq([{ sku: "B", quantity: 1 }])
      end

      it "grants multiple sets when repeatable" do
        free_item_discount(repeatable: true)
        items = [{ sku: "A", quantity: 6, unit_price: 10 }, { sku: "B", quantity: 5, unit_price: 5 }]
        result = validate(line_items: items)
        expect(result[:applicable_discounts].first[:free_items]).to eq([{ sku: "B", quantity: 3 }])
      end

      it "caps free_quantity at the matched target's own quantity" do
        free_item_discount(repeatable: true)
        items = [{ sku: "A", quantity: 20, unit_price: 10 }, { sku: "B", quantity: 2, unit_price: 5 }]
        result = validate(line_items: items)
        expect(result[:applicable_discounts].first[:free_items]).to eq([{ sku: "B", quantity: 2 }])
      end
    end
  end

  describe "eligibility_condition" do
    it "includes the discount when eligibility_condition passes" do
      discount = active_promotion(eligibility_condition: { entity: "customer", key: "tier", operator: "eq", value: "gold" })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items, customer: { external_id: "c1", tier: "gold" })
      expect(result[:total_amount_off]).to eq(5.0)
    end

    it "excludes the discount when eligibility_condition fails" do
      discount = active_promotion(eligibility_condition: { entity: "customer", key: "tier", operator: "eq", value: "gold" })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items, customer: { external_id: "c1", tier: "silver" })
      expect(result[:applicable_discounts]).to be_empty
    end
  end

  describe "active windows" do
    it "excludes a discount with no active_from (fails closed)" do
      discount = create(:discount, project: project, campaign: campaign, kind: "promotion", kind_config: {})
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items)
      expect(result[:applicable_discounts]).to be_empty
    end

    it "excludes a discount before its active_from" do
      discount = create(:discount, project: project, campaign: campaign, kind: "promotion", kind_config: { active_from: 1.day.from_now.iso8601 })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items)
      expect(result[:applicable_discounts]).to be_empty
    end

    it "excludes a discount after its active_until" do
      discount = active_promotion(kind_config: { active_from: 1.year.ago.iso8601, active_until: 1.day.ago.iso8601 })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items)
      expect(result[:applicable_discounts]).to be_empty
    end

    it "includes a discount inside its active window" do
      discount = active_promotion(kind_config: { active_from: 1.year.ago.iso8601, active_until: 1.year.from_now.iso8601 })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items)
      expect(result[:total_amount_off]).to eq(5.0)
    end

    it "excludes every discount under a disabled campaign" do
      disabled_campaign = create(:campaign, project: project, enabled: false)
      discount = create(:discount, project: project, campaign: disabled_campaign, kind: "promotion", kind_config: { active_from: 1.year.ago.iso8601 })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items)
      expect(result[:applicable_discounts]).to be_empty
    end

    it "excludes every discount under an archived campaign" do
      archived_campaign = create(:campaign, project: project, archived: true)
      discount = create(:discount, project: project, campaign: archived_campaign, kind: "promotion", kind_config: { active_from: 1.year.ago.iso8601 })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items)
      expect(result[:applicable_discounts]).to be_empty
    end
  end

  describe "coupon gating" do
    def coupon_result(code)
      result = validate(line_items: line_items, coupon_codes: [code])
      result[:coupons].find { |c| c[:code] == code }
    end

    it "reports 'not found' for an unknown code" do
      expect(coupon_result("NOPE")[:reason]).to eq("not found")
    end

    it "reports 'campaign inactive' when the campaign is disabled" do
      inactive_campaign = create(:campaign, project: project, enabled: false)
      discount = create(:discount, project: project, campaign: inactive_campaign, kind: "coupon")
      create(:coupon, discount: discount, project: project, code: "C1")

      expect(coupon_result("C1")[:reason]).to eq("campaign inactive")
    end

    it "reports 'not yet valid' before the coupon's valid_from" do
      discount = create(:discount, project: project, campaign: campaign, kind: "coupon", kind_config: { valid_from: 1.day.from_now.iso8601 })
      create(:coupon, discount: discount, project: project, code: "C2")

      expect(coupon_result("C2")[:reason]).to eq("not yet valid")
    end

    it "reports 'expired' after the coupon's valid_until" do
      discount = create(:discount, project: project, campaign: campaign, kind: "coupon", kind_config: { valid_until: 1.day.ago.iso8601 })
      create(:coupon, discount: discount, project: project, code: "C3")

      expect(coupon_result("C3")[:reason]).to eq("expired")
    end

    it "reports 'not assigned to this customer' when the code is bound to someone else" do
      discount = create(:discount, project: project, campaign: campaign, kind: "coupon")
      other_customer = create(:customer, project: project)
      create(:coupon, discount: discount, project: project, code: "C4", customer: other_customer)

      result = validate(line_items: line_items, customer: { external_id: "someone-else" }, coupon_codes: ["C4"])
      expect(result[:coupons].find { |c| c[:code] == "C4" }[:reason]).to eq("not assigned to this customer")
    end

    it "reports 'already redeemed' once remaining_redemptions hits zero" do
      discount = create(:discount, project: project, campaign: campaign, kind: "coupon")
      coupon_code = create(:coupon, discount: discount, project: project, code: "C5", max_redemptions: 1)
      customer = create(:customer, project: project)
      redemption = create(:redemption, coupon_code: coupon_code, discount: discount, customer: customer)
      order = create(:order, project: project, customer: customer)
      create(:order_discount, order: order, discount: discount, redemption: redemption, kind: "coupon")

      expect(coupon_result("C5")[:reason]).to eq("already redeemed")
    end

    it "reports 'not eligible' when the discount's eligibility_condition fails" do
      discount = create(:discount, project: project, campaign: campaign, kind: "coupon",
                                    eligibility_condition: { entity: "customer", key: "tier", operator: "eq", value: "gold" })
      create(:coupon, discount: discount, project: project, code: "C6")

      result = validate(line_items: line_items, customer: { external_id: "c1", tier: "silver" }, coupon_codes: ["C6"])
      expect(result[:coupons].find { |c| c[:code] == "C6" }[:reason]).to eq("not eligible")
    end

    it "surfaces UsageLimitChecker's own reason when the discount-level limit is reached" do
      discount = create(:discount, project: project, campaign: campaign, kind: "coupon", max_redemptions: 1)
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })
      order = create(:order, project: project)
      create(:order_discount, order: order, discount: discount, kind: "coupon")
      create(:coupon, discount: discount, project: project, code: "C7")

      expect(coupon_result("C7")[:reason]).to eq("redemption limit reached")
    end

    it "reports 'conflicts with another applied discount' when it loses to stacking" do
      winner = active_promotion(stackable: false)
      create(:discount_effect, discount: winner, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 50, currency: "USD" })

      loser = create(:discount, project: project, campaign: campaign, kind: "coupon", stackable: false)
      create(:discount_effect, discount: loser, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })
      create(:coupon, discount: loser, project: project, code: "C8")

      result = coupon_result("C8")
      expect(result[:valid]).to eq(false)
      expect(result[:reason]).to eq("conflicts with another applied discount")
    end

    it "reports valid: true with the matched discounts for a genuinely eligible code" do
      discount = create(:discount, project: project, campaign: campaign, kind: "coupon")
      create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 20 })
      create(:coupon, discount: discount, project: project, code: "C9")

      result = coupon_result("C9")
      expect(result[:valid]).to eq(true)
      expect(result[:reason]).to be_nil
      expect(result[:discounts]).not_to be_empty
    end
  end

  describe "as_of" do
    it "lets a future-dated discount apply when as_of simulates that future time" do
      discount = create(:discount, project: project, campaign: campaign, kind: "promotion", kind_config: { active_from: 10.days.from_now.iso8601 })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items, as_of: 20.days.from_now.iso8601)
      expect(result[:total_amount_off]).to eq(5.0)
    end

    it "raises a ValidationError on field as_of for an unparsable value" do
      expect { validate(line_items: line_items, as_of: "not-a-time") }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "as_of"))
      end
    end

    it "uses the real clock when as_of is blank" do
      discount = active_promotion
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items, as_of: nil)
      expect(result[:total_amount_off]).to eq(5.0)
    end
  end

  describe "customer lookup" do
    it "doesn't error for an unknown customer, with no tier and a zero balance" do
      result = validate(line_items: line_items, customer: { external_id: "never-seen" }, redeem_points: 10)
      expect(result[:points_redemption][:balance]).to eq(0)
      expect(result[:points_redemption][:applied]).to eq(0)
    end

    it "drives eligibility off the customer's real persisted membership tier, not a submitted one" do
      scheme = create(:membership_scheme, project: project)
      tier = create(:membership_tier, membership_scheme: scheme, name: "Gold")
      customer = create(:customer, project: project, external_id: "vip-1", membership_tier: tier, membership_tier_entered_at: Time.now.utc)

      discount = active_promotion(eligibility_condition: { entity: "customer", key: "membership_tier", operator: "eq", value: "Gold" })
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      spoofed = validate(line_items: line_items, customer: { external_id: "vip-1", membership_tier: "Bronze" })
      expect(spoofed[:total_amount_off]).to eq(5.0)
    end
  end

  describe "loyalty discounts" do
    it "computes points_flat" do
      discount = active_loyalty
      create(:discount_effect, discount: discount, effect_type: "points_flat", scope: "cart", config: { points: 50 })

      result = validate(line_items: line_items)
      expect(result[:loyalty_points]).to include(total_points: 50, base_points: 50, multiplier: 1.0)
    end

    it "computes points_per_currency against the cart total" do
      discount = active_loyalty
      create(:discount_effect, discount: discount, effect_type: "points_per_currency", scope: "cart", config: { rate: 2 })

      result = validate(line_items: [{ sku: "X", quantity: 1, unit_price: 100 }])
      expect(result[:loyalty_points][:total_points]).to eq(200)
    end

    it "computes points_per_item per matching line item at line_item scope" do
      discount = active_loyalty
      create(:discount_effect, discount: discount, effect_type: "points_per_item", scope: "line_item", config: { points_per_item: 5 },
                                target_condition: { entity: "line_item", key: "sku", operator: "eq", value: "X" })

      result = validate(line_items: [{ sku: "X", quantity: 3, unit_price: 10 }])
      expect(result[:loyalty_points][:total_points]).to eq(15)
    end

    # points_per_item at cart scope isn't a reachable state — DiscountEffect's own
    # validation (validate_kind_compatibility) requires scope: line_item for this
    # effect_type, so ValidationService's defensive `return [] unless line_item`
    # guard for it can't actually be exercised through persisted data.

    it "combines a flat-earning discount with a multiplier as base_points * multiplier" do
      earning = active_loyalty
      create(:discount_effect, discount: earning, effect_type: "points_flat", scope: "cart", config: { points: 100 })
      multiplier_discount = active_loyalty
      create(:discount_effect, discount: multiplier_discount, effect_type: "points_multiplier", scope: "cart", config: { multiplier: 2 })

      result = validate(line_items: line_items)
      expect(result[:loyalty_points]).to include(total_points: 200, base_points: 100, multiplier: 2.0)
    end

    it "still enforces a multiplier-only discount's own count-based max_redemptions despite its zero amount" do
      earning = active_loyalty
      create(:discount_effect, discount: earning, effect_type: "points_flat", scope: "cart", config: { points: 100 })

      multiplier_discount = active_loyalty(max_redemptions: 1)
      create(:discount_effect, discount: multiplier_discount, effect_type: "points_multiplier", scope: "cart", config: { multiplier: 2 })
      order = create(:order, project: project)
      create(:order_discount, order: order, discount: multiplier_discount, kind: "loyalty")

      result = validate(line_items: line_items)
      expect(result[:loyalty_points]).to include(total_points: 100, multiplier: 1.0)
    end
  end

  describe "points redemption" do
    let(:customer) { create(:customer, project: project, external_id: "cust-1") }

    it "caps at the customer's actual balance" do
      create(:loyalty_point_lot, customer: customer, points: 20)

      result = validate(line_items: [{ sku: "X", quantity: 1, unit_price: 100 }], customer: { external_id: "cust-1" }, redeem_points: 1000)
      expect(result[:points_redemption]).to include(requested: 1000, applied: 20, balance: 20)
    end

    it "caps at the requested amount" do
      create(:loyalty_point_lot, customer: customer, points: 1000)

      result = validate(line_items: [{ sku: "X", quantity: 1, unit_price: 1000 }], customer: { external_id: "cust-1" }, redeem_points: 10)
      expect(result[:points_redemption][:applied]).to eq(10)
    end

    it "caps at the remaining payable amount after other discounts" do
      create(:loyalty_point_lot, customer: customer, points: 1000)
      discount = active_promotion
      create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 50 })

      result = validate(line_items: [{ sku: "X", quantity: 1, unit_price: 100 }], customer: { external_id: "cust-1" }, redeem_points: 1000)
      expect(result[:points_redemption][:applied]).to eq(50)
    end

    it "never applies a negative amount when discounts already exceed the cart total" do
      create(:loyalty_point_lot, customer: customer, points: 1000)
      discount = active_promotion
      create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 1000, currency: "USD" })

      result = validate(line_items: [{ sku: "X", quantity: 1, unit_price: 100 }], customer: { external_id: "cust-1" }, redeem_points: 1000)
      expect(result[:points_redemption][:applied]).to eq(0)
    end
  end

  describe "stacking integration" do
    it "excludes an individually-eligible discount that loses to a higher-value conflicting one" do
      winner = active_promotion(stackable: false)
      create(:discount_effect, discount: winner, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 50, currency: "USD" })

      loser = active_promotion(stackable: false)
      create(:discount_effect, discount: loser, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" })

      result = validate(line_items: line_items)
      expect(result[:total_amount_off]).to eq(50.0)
      discount_ids = result[:applicable_discounts].map { |d| d[:discount_id] }
      expect(discount_ids).to eq([winner.public_id])
    end

    it "values a free_item candidate by the matched line item's price, so it can outrank a lower-dollar amount_off candidate" do
      free_item = active_promotion(stackable: false)
      create(:discount_effect, discount: free_item, effect_type: "free_item", scope: "cart",
                                config: {
                                  buy_quantity: 1, get_quantity: 1, repeatable: false,
                                  buy_condition: { entity: "line_item", key: "sku", operator: "eq", value: "A" },
                                  get_condition: { entity: "line_item", key: "sku", operator: "eq", value: "B" }
                                })

      cheap_amount_off = active_promotion(stackable: false)
      create(:discount_effect, discount: cheap_amount_off, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 1, currency: "USD" })

      items = [{ sku: "A", quantity: 1, unit_price: 10 }, { sku: "B", quantity: 1, unit_price: 50 }]
      result = validate(line_items: items)

      discount_ids = result[:applicable_discounts].map { |d| d[:discount_id] }
      expect(discount_ids).to eq([free_item.public_id])
    end
  end
end
