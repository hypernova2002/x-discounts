require "rails_helper"

RSpec.describe OrderLineItemResource do
  it "renders the line item's fields, including metadata as a plain hash" do
    order = create(:order)
    order.add_order_line_item(sku: "X", quantity: 2, unit_price: 10, metadata: { gift_wrap: true })
    line_item = order.order_line_items_dataset.first

    hash = described_class.new(line_item).to_h

    expect(hash["sku"]).to eq("X")
    expect(hash["quantity"]).to eq(2)
    expect(hash["unit_price"].to_s).to eq("10.0")
    expect(hash["metadata"]).to eq({ "gift_wrap" => true })
  end
end
