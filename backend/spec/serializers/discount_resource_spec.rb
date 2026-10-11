# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscountResource do
  let(:discount) { create(:discount, kind: "promotion") }

  it "omits every gated field by default" do
    hash = described_class.new(discount).to_h

    expect(hash).not_to have_key("campaign")
    expect(hash).not_to have_key("effects")
    expect(hash).not_to have_key("compatible_discounts")
    expect(hash).not_to have_key("coupon_code_stats")
    expect(hash).not_to have_key("redemption_count")
    expect(hash).not_to have_key("points_earned")
    expect(hash).not_to have_key("points_redeemed")
  end

  it "includes a gated field when requested, via its per-record fallback" do
    create(:order_discount, discount: discount, kind: "promotion")

    hash = described_class.new(discount, params: { includes: %w[campaign redemption_count] }).to_h

    expect(hash["campaign"]).to be_present
    expect(hash["redemption_count"]).to eq(1)
  end

  it "prefers a bulk-provided redemption_counts map over the per-record fallback" do
    create(:order_discount, discount: discount, kind: "promotion")

    hash = described_class.new(discount, params: { includes: ["redemption_count"], redemption_counts: { discount.id => 99 } }).to_h

    expect(hash["redemption_count"]).to eq(99)
  end

  it "prefers a bulk-provided coupon_code_stats map over the per-record fallback" do
    coupon_discount = create(:discount, kind: "coupon")

    hash = described_class.new(
      coupon_discount,
      params: { includes: ["coupon_code_stats"], coupon_code_stats: { coupon_discount.id => { total: 3, available: 2 } } }
    ).to_h

    expect(hash["coupon_code_stats"]).to eq(total: 3, available: 2)
  end
end
