require "rails_helper"

RSpec.describe GiftShop::RedeemItemService do
  let(:project) { create(:project) }
  let(:item) { create(:gift_shop_item, project: project, points_cost: 50, stock: 10) }
  let(:customer) { create(:customer, project: project) }

  before { create(:loyalty_point_lot, customer: customer, points: 100) }

  it "records a gift_shop_redemption activity event matching the redemption" do
    described_class.new(project: project, item: item, customer_external_id: customer.external_id, quantity: 2).call

    events = customer.customer_activity_events_dataset.all
    expect(events.map(&:type)).to eq(["gift_shop_redemption"])
    expect(events.first.payload.to_h).to include("item_name" => item.name, "quantity" => 2, "points_spent" => 100)
  end
end
