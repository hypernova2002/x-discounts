require "rails_helper"

RSpec.describe CouponCodeResource do
  it "renders the code's plain fields" do
    coupon_code = create(:coupon, code: "SAVE10", max_redemptions: 5)
    hash = described_class.new(coupon_code).to_h

    expect(hash["id"]).to eq(coupon_code.public_id)
    expect(hash["code"]).to eq("SAVE10")
    expect(hash["max_redemptions"]).to eq(5)
  end

  it "omits redemption_count, remaining_redemptions, and customer by default" do
    coupon_code = create(:coupon)
    hash = described_class.new(coupon_code).to_h
    expect(hash).not_to have_key("redemption_count")
    expect(hash).not_to have_key("remaining_redemptions")
    expect(hash).not_to have_key("customer")
  end

  it "falls back to a live redemption_count query when no bulk map is given" do
    coupon_code = create(:coupon, max_redemptions: 5)
    hash = described_class.new(coupon_code, params: { includes: ["redemption_count"] }).to_h
    expect(hash["redemption_count"]).to eq(0)
  end

  it "prefers a bulk-provided redemption_counts map over the live query" do
    coupon_code = create(:coupon)
    hash = described_class.new(coupon_code, params: { includes: ["redemption_count"], redemption_counts: { coupon_code.id => 7 } }).to_h
    expect(hash["redemption_count"]).to eq(7)
  end

  it "includes remaining_redemptions when requested" do
    coupon_code = create(:coupon, max_redemptions: 5)
    hash = described_class.new(coupon_code, params: { includes: ["remaining_redemptions"] }).to_h
    expect(hash["remaining_redemptions"]).to eq(5)
  end

  it "includes a minimal customer when requested and bound" do
    customer = create(:customer, external_id: "cust-1", name: "Jane")
    coupon_code = create(:coupon, customer: customer)

    hash = described_class.new(coupon_code, params: { includes: ["customer"] }).to_h

    expect(hash["customer"]).to eq({ id: customer.public_id, external_id: "cust-1", name: "Jane" })
  end

  it "includes a nil customer when requested but unbound" do
    coupon_code = create(:coupon, customer: nil)
    hash = described_class.new(coupon_code, params: { includes: ["customer"] }).to_h
    expect(hash["customer"]).to be_nil
  end
end
