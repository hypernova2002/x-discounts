require "rails_helper"

RSpec.describe PointsRedemptionResource do
  it "renders the always-on fields" do
    points_redemption = create(:points_redemption, points_redeemed: 100, amount_off: 5)
    hash = described_class.new(points_redemption).to_h

    expect(hash["id"]).to eq(points_redemption.public_id)
    expect(hash["points_redeemed"]).to eq(100)
    expect(hash["amount_off"].to_s).to eq("5.0")
  end

  it "omits refund_history by default" do
    points_redemption = create(:points_redemption)
    expect(described_class.new(points_redemption).to_h).not_to have_key("refund_history")
  end

  it "includes refund_history, reading the redemption_refund lots it created" do
    customer = create(:customer)
    points_redemption = create(:points_redemption, customer: customer, points_redeemed: 50)
    Refunds::CreateService.new(points_redemption: points_redemption, points: 20, reason: "goodwill").call

    hash = described_class.new(points_redemption, params: { includes: ["refund_history"] }).to_h

    expect(hash["refund_history"].size).to eq(1)
    expect(hash["refund_history"].first).to include(points: 20, amount_off: nil, reason: "goodwill")
  end
end
