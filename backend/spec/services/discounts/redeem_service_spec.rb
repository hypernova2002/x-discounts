require "rails_helper"

RSpec.describe Discounts::RedeemService do
  let(:project) { create(:project) }

  it "records an order activity event with the earned/redeemed/discount totals" do
    discount = create(:discount, project: project, kind: "promotion", key: "sitewide10",
                                  kind_config: { active_from: 1.year.ago.iso8601 })
    create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })

    result = described_class.new(
      project: project,
      cart: {},
      line_items: [{ sku: "X", quantity: 1, unit_price: 100 }],
      customer: { external_id: "cust-1" }
    ).call
    order = result[:order]

    customer = Customer.first(project_id: project.id, external_id: "cust-1")
    events = customer.customer_activity_events_dataset.all
    expect(events.map(&:type)).to eq(["order"])
    expect(events.first.payload.to_h).to include(
      "order_id" => order.public_id,
      "total_amount" => "100.0",
      "total_discount_amount" => "10.0",
      "total_points_earned" => 0,
      "total_points_redeemed" => 0
    )
  end
end
