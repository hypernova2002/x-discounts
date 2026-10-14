require "rails_helper"

RSpec.describe LoyaltyPointLotResource do
  it "renders the lot's always-on fields" do
    lot = create(:loyalty_point_lot, points: 100, source: "manual_grant", reason: "goodwill")
    hash = described_class.new(lot).to_h

    expect(hash["id"]).to eq(lot.public_id)
    expect(hash["points"]).to eq(100)
    expect(hash["source"]).to eq("manual_grant")
    expect(hash["expired"]).to eq(false)
    expect(hash["reason"]).to eq("goodwill")
  end

  it "omits points_remaining, status, order_id, discount_name, and performed_by by default" do
    lot = create(:loyalty_point_lot)
    hash = described_class.new(lot).to_h
    %w[points_remaining status order_id discount_name performed_by].each { |key| expect(hash).not_to have_key(key) }
  end

  it "falls back to a live points_remaining/status computation when no bulk map is given" do
    lot = create(:loyalty_point_lot, points: 50)
    hash = described_class.new(lot, params: { includes: %w[points_remaining status] }).to_h

    expect(hash["points_remaining"]).to eq(50)
    expect(hash["status"]).to eq("active")
  end

  it "prefers bulk-provided points_remaining_by_lot/status_by_lot maps over the live computation" do
    lot = create(:loyalty_point_lot, points: 50)
    hash = described_class.new(
      lot, params: { includes: %w[points_remaining status], points_remaining_by_lot: { lot.id => 10 }, status_by_lot: { lot.id => "expired" } }
    ).to_h

    expect(hash["points_remaining"]).to eq(10)
    expect(hash["status"]).to eq("expired")
  end

  it "includes order_id, discount_name, and performed_by when requested" do
    order = create(:order)
    discount = create(:discount, name: "Sitewide 10%")
    user = create(:user, name: "Admin User")
    lot = create(:loyalty_point_lot, order: order, discount: discount, performed_by_user: user)

    hash = described_class.new(lot, params: { includes: %w[order_id discount_name performed_by] }).to_h

    expect(hash["order_id"]).to eq(order.public_id)
    expect(hash["discount_name"]).to eq("Sitewide 10%")
    expect(hash["performed_by"]).to eq("Admin User")
  end
end
