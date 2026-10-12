# frozen_string_literal: true

require "rails_helper"

RSpec.describe Discounts::UsageLimitChecker do
  let(:project) { create(:project) }
  let(:now) { Time.utc(2026, 6, 15, 12, 0, 0) }

  def checker_for(discount, customer_external_id: nil)
    described_class.new(discount: discount, customer: { external_id: customer_external_id }, project: project, now: now)
  end

  describe "#ok? / #reason" do
    it "is ok when there are no limits configured" do
      discount = create(:discount, project: project, kind: "promotion")

      expect(checker_for(discount)).to be_ok
    end

    it "reports the overall redemption limit reached, counting non-refunded order_discounts only" do
      discount = create(:discount, project: project, kind: "promotion", max_redemptions: 1)
      create(:order_discount, discount: discount, kind: "promotion", created_at: now)

      expect(checker_for(discount)).not_to be_ok
      expect(checker_for(discount).reason).to eq("redemption limit reached")
    end

    it "does not count a coupon-kind row refunded via a DiscountRefund against the overall limit" do
      discount = create(:discount, project: project, kind: "coupon", max_redemptions: 1)
      refunded = create(:order_discount, discount: discount, kind: "coupon", created_at: now)
      create(:discount_refund, order_discount: refunded)

      expect(checker_for(discount)).to be_ok
    end

    it "does not count a loyalty-kind row clawed back via a ledger entry against the overall limit" do
      discount = create(:discount, project: project, kind: "loyalty", max_redemptions: 1)
      lot = create(:loyalty_point_lot)
      clawed_back = create(:order_discount, discount: discount, kind: "loyalty", loyalty_point_lot: lot, created_at: now)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "clawback", order_discount: clawed_back)

      expect(checker_for(discount)).to be_ok
    end

    it "reports the per-customer redemption limit reached" do
      discount = create(:discount, project: project, kind: "promotion", max_redemptions_per_customer: 1)
      customer = create(:customer, project: project, external_id: "cust-1")
      order = create(:order, project: project, customer: customer)
      create(:order_discount, discount: discount, kind: "promotion", order: order, created_at: now)

      checker = checker_for(discount, customer_external_id: "cust-1")
      expect(checker).not_to be_ok
      expect(checker.reason).to eq("per-customer redemption limit reached")
    end

    it "does not count another customer's redemptions against the per-customer limit" do
      discount = create(:discount, project: project, kind: "promotion", max_redemptions_per_customer: 1)
      other_customer = create(:customer, project: project, external_id: "other")
      other_order = create(:order, project: project, customer: other_customer)
      create(:order_discount, discount: discount, kind: "promotion", order: other_order, created_at: now)

      checker = checker_for(discount, customer_external_id: "cust-1")
      expect(checker).to be_ok
    end

    it "reports the daily redemption limit reached, scoped to the given day" do
      discount = create(:discount, project: project, kind: "promotion", max_redemptions_per_day: 1)
      create(:order_discount, discount: discount, kind: "promotion", created_at: now)
      create(:order_discount, discount: discount, kind: "promotion", created_at: now - (2 * 24 * 60 * 60))

      checker = checker_for(discount)
      expect(checker).not_to be_ok
      expect(checker.reason).to eq("daily redemption limit reached")
    end

    it "reports the total amount limit reached once the candidate amount would push it over" do
      discount = create(:discount, project: project, kind: "promotion", max_redemption_amount: 100)
      create(:order_discount, discount: discount, kind: "promotion", amount_off: 90, created_at: now)

      checker = checker_for(discount)
      expect(checker.ok?(candidate_amount: 20)).to be(false)
      expect(checker.reason(candidate_amount: 20)).to eq("campaign redemption amount limit reached")
      expect(checker.ok?(candidate_amount: 5)).to be(true)
    end

    it "excludes a refunded row's amount_off from the total amount limit" do
      discount = create(:discount, project: project, kind: "coupon", max_redemption_amount: 100)
      refunded = create(:order_discount, discount: discount, kind: "coupon", amount_off: 90, created_at: now)
      create(:discount_refund, order_discount: refunded)

      checker = checker_for(discount)
      expect(checker.ok?(candidate_amount: 20)).to be(true)
    end

    it "reports the per-day amount limit reached" do
      discount = create(:discount, project: project, kind: "promotion", max_redemption_amount_per_day: 50)
      create(:order_discount, discount: discount, kind: "promotion", amount_off: 40, created_at: now)

      checker = checker_for(discount)
      expect(checker.ok?(candidate_amount: 20)).to be(false)
      expect(checker.reason(candidate_amount: 20)).to eq("daily redemption amount limit reached")
    end

    it "reports the per-customer amount limit reached" do
      discount = create(:discount, project: project, kind: "promotion", max_redemption_amount_per_customer: 50)
      customer = create(:customer, project: project, external_id: "cust-1")
      order = create(:order, project: project, customer: customer)
      create(:order_discount, discount: discount, kind: "promotion", order: order, amount_off: 40, created_at: now)

      checker = checker_for(discount, customer_external_id: "cust-1")
      expect(checker.ok?(candidate_amount: 20)).to be(false)
      expect(checker.reason(candidate_amount: 20)).to eq("per-customer redemption amount limit reached")
    end
  end
end
