require "rails_helper"

RSpec.describe GiftShopItems::UpdateService do
  let(:project) { create(:project) }
  let(:item) { create(:gift_shop_item, project: project, name: "Old Name", points_cost: 100, stock: 10, enabled: true) }

  it "updates only name when only name is sent" do
    request = GiftShopItemUpdateRequest.new(name: "New Name")
    updated = described_class.new(item: item, request: request).call
    expect(updated.name).to eq("New Name")
    expect(updated.points_cost).to eq(100)
  end

  it "updates only points_cost when only points_cost is sent" do
    request = GiftShopItemUpdateRequest.new(points_cost: 200)
    updated = described_class.new(item: item, request: request).call
    expect(updated.points_cost).to eq(200)
  end

  it "updates only stock when only stock is sent" do
    request = GiftShopItemUpdateRequest.new(stock: 5)
    updated = described_class.new(item: item, request: request).call
    expect(updated.stock).to eq(5)
  end

  it "leaves every field untouched when the request is empty" do
    request = GiftShopItemUpdateRequest.new({})
    updated = described_class.new(item: item, request: request).call
    expect(updated.name).to eq("Old Name")
    expect(updated.points_cost).to eq(100)
  end

  it "raises a ValidationError when points_cost exceeds the model's bound" do
    request = GiftShopItemUpdateRequest.new(points_cost: 10_000_001)
    expect { described_class.new(item: item, request: request).call }.to raise_error(ValidationError)
  end
end
