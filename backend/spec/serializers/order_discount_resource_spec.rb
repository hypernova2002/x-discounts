require "rails_helper"

RSpec.describe OrderDiscountResource do
  it "renders the always-on fields" do
    order_discount = create(:order_discount, kind: "coupon", discount_key: "save10", discount_name: "Save 10", effect_type: "percentage_off", amount_off: 10, sku: "X")
    hash = described_class.new(order_discount).to_h

    expect(hash["id"]).to eq(order_discount.public_id)
    expect(hash["kind"]).to eq("coupon")
    expect(hash["discount_key"]).to eq("save10")
    expect(hash["discount_name"]).to eq("Save 10")
    expect(hash["effect_type"]).to eq("percentage_off")
    expect(hash["amount_off"].to_s).to eq("10.0")
    expect(hash["sku"]).to eq("X")
  end

  it "renders free_items as nil when none" do
    order_discount = create(:order_discount)
    expect(described_class.new(order_discount).to_h["free_items"]).to be_nil
  end

  it "omits points_earned, refunded_points, refunded_amount_off, discount_id, and refundable by default" do
    order_discount = create(:order_discount)
    hash = described_class.new(order_discount).to_h
    %w[points_earned refunded_points refunded_amount_off discount_id refundable].each { |key| expect(hash).not_to have_key(key) }
  end

  it "includes discount_id and refundable when requested" do
    discount = create(:discount, refundable: true)
    order_discount = create(:order_discount, discount: discount)

    hash = described_class.new(order_discount, params: { includes: %w[discount_id refundable] }).to_h

    expect(hash["discount_id"]).to eq(discount.public_id)
    expect(hash["refundable"]).to eq(true)
  end

  describe "refund_history" do
    it "is empty for a loyalty line with no linked lot" do
      order_discount = create(:order_discount, kind: "loyalty", loyalty_point_lot: nil, amount_off: nil)
      hash = described_class.new(order_discount, params: { includes: ["refund_history"] }).to_h
      expect(hash["refund_history"]).to eq([])
    end

    it "reads clawback ledger entries for a loyalty line's linked lot" do
      customer = create(:customer)
      lot = create(:loyalty_point_lot, customer: customer, points: 50)
      order_discount = create(:order_discount, kind: "loyalty", loyalty_point_lot: lot, amount_off: nil)
      Refunds::CreateService.new(order_discount: order_discount, points: 20, reason: "goodwill").call

      hash = described_class.new(order_discount, params: { includes: ["refund_history"] }).to_h

      expect(hash["refund_history"].size).to eq(1)
      expect(hash["refund_history"].first).to include(points: 20, amount_off: nil, reason: "goodwill")
    end

    it "reads discount_refunds for a non-loyalty line" do
      order_discount = create(:order_discount, kind: "coupon", amount_off: 10)
      Refunds::CreateService.new(order_discount: order_discount, amount_off: 4, reason: "goodwill").call

      hash = described_class.new(order_discount, params: { includes: ["refund_history"] }).to_h

      expect(hash["refund_history"].size).to eq(1)
      expect(hash["refund_history"].first).to include(points: nil, amount_off: 4, reason: "goodwill")
    end
  end
end
