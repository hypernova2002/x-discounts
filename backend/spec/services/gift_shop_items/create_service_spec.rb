require "rails_helper"

RSpec.describe GiftShopItems::CreateService do
  let(:project) { create(:project) }

  it "creates an item with the given fields" do
    request = GiftShopItemRequest.new(name: "Mug", description: "A mug", points_cost: 100, stock: 50, enabled: false)
    item = described_class.new(project: project, request: request).call

    expect(item.name).to eq("Mug")
    expect(item.description).to eq("A mug")
    expect(item.points_cost).to eq(100)
    expect(item.stock).to eq(50)
    expect(item.enabled).to eq(false)
  end

  it "raises a ValidationError when points_cost exceeds the model's bound" do
    request = GiftShopItemRequest.new(name: "Mug", points_cost: 10_000_001)
    expect { described_class.new(project: project, request: request).call }.to raise_error(ValidationError)
  end
end
