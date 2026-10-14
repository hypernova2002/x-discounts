require "rails_helper"

RSpec.describe GiftShopRedemptionResource do
  it "renders the redemption's plain fields" do
    redemption = create(:gift_shop_redemption, item_name: "Mug", quantity: 2, points_spent: 200)
    hash = described_class.new(redemption).to_h

    expect(hash["id"]).to eq(redemption.public_id)
    expect(hash["item_name"]).to eq("Mug")
    expect(hash["quantity"]).to eq(2)
    expect(hash["points_spent"]).to eq(200)
  end

  it "omits item_id and customer_id by default" do
    redemption = create(:gift_shop_redemption)
    hash = described_class.new(redemption).to_h
    expect(hash).not_to have_key("item_id")
    expect(hash).not_to have_key("customer_id")
  end

  it "includes item_id and customer_id when requested" do
    redemption = create(:gift_shop_redemption)
    hash = described_class.new(redemption, params: { includes: %w[item_id customer_id] }).to_h

    expect(hash["item_id"]).to eq(redemption.gift_shop_item.public_id)
    expect(hash["customer_id"]).to eq(redemption.customer.public_id)
  end
end
