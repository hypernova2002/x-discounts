# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderResource do
  let(:order) { create(:order) }

  it "omits every gated field by default, but keeps status always-on" do
    hash = described_class.new(order).to_h

    expect(hash).not_to have_key("customer")
    expect(hash).not_to have_key("line_items")
    expect(hash).not_to have_key("discounts")
    expect(hash).not_to have_key("points_redemption")
    expect(hash["status"]).to eq("active")
  end

  it "forwards a single flat includes set into nested order_discounts, gating their own fields too" do
    order_discount = create(:order_discount, order: order, kind: "promotion")

    hash = described_class.new(order, params: { includes: %w[order_discounts refundable] }).to_h

    expect(hash["discounts"]).to be_present
    nested = hash["discounts"].first
    expect(nested["id"]).to eq(order_discount.public_id)
    expect(nested["refundable"]).to eq(true)
    expect(nested).not_to have_key("refund_history")
  end

  it "forwards includes into the nested points_redemption's own gated refund_history" do
    create(:points_redemption, order: order)

    hash = described_class.new(order, params: { includes: %w[points_redemption refund_history] }).to_h

    expect(hash["points_redemption"]).to be_present
    expect(hash["points_redemption"]["refund_history"]).to eq([])
  end
end
