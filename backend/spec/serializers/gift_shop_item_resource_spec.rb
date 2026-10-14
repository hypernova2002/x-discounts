require "rails_helper"

RSpec.describe GiftShopItemResource do
  it "renders the item's fields" do
    item = create(:gift_shop_item, name: "Mug", points_cost: 100)
    hash = described_class.new(item).to_h

    expect(hash["id"]).to eq(item.public_id)
    expect(hash["name"]).to eq("Mug")
    expect(hash["points_cost"]).to eq(100)
  end

  it "reports in_stock: true when stock is nil (unlimited)" do
    item = create(:gift_shop_item, stock: nil)
    expect(described_class.new(item).to_h["in_stock"]).to eq(true)
  end

  it "reports in_stock: true when stock is positive" do
    item = create(:gift_shop_item, stock: 5)
    expect(described_class.new(item).to_h["in_stock"]).to eq(true)
  end

  it "reports in_stock: false when stock is zero" do
    item = create(:gift_shop_item, stock: 0)
    expect(described_class.new(item).to_h["in_stock"]).to eq(false)
  end

  it "reports photo_url: nil when the item has no photo" do
    item = create(:gift_shop_item)
    expect(described_class.new(item).to_h["photo_url"]).to be_nil
  end

  it "reports a photo_url when the item has a photo" do
    item = create(:gift_shop_item, photo_filename: "mug.png")
    hash = described_class.new(item).to_h
    expect(hash["photo_url"]).to eq("/api/v1/admin/gift_shop_items/#{item.public_id}/photo")
  end
end
