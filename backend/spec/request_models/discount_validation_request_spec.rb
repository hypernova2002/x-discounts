require "rails_helper"

RSpec.describe DiscountValidationRequest do
  it "accepts a fully empty body, defaulting every field" do
    record = described_class.new({})
    expect(record.cart).to eq({})
    expect(record.line_items).to eq([])
    expect(record.customer).to eq({})
    expect(record.coupon_codes).to eq([])
    expect(record.redeem_points).to eq(0)
  end

  it "keeps cart as a raw hash, including keys the struct doesn't know about" do
    record = described_class.new(cart: { currency: "USD", custom_field: "anything" })
    expect(record.cart).to eq({ currency: "USD", custom_field: "anything" })
  end

  it "keeps line_items as raw hashes" do
    record = described_class.new(line_items: [{ sku: "X", quantity: 1, unit_price: 10 }])
    expect(record.line_items).to eq([{ sku: "X", quantity: 1, unit_price: 10 }])
  end

  it "rejects a non-array line_items" do
    expect { described_class.new(line_items: { sku: "X" }) }.to raise_error(Dry::Struct::Error)
  end

  it "keeps customer as a raw hash" do
    record = described_class.new(customer: { external_id: "cust-1", loyalty_tier: "gold" })
    expect(record.customer).to eq({ external_id: "cust-1", loyalty_tier: "gold" })
  end

  it "accepts an explicit coupon_codes array" do
    expect(described_class.new(coupon_codes: %w[SAVE10 SAVE20]).coupon_codes).to eq(%w[SAVE10 SAVE20])
  end

  it "accepts a positive redeem_points" do
    expect(described_class.new(redeem_points: 50).redeem_points).to eq(50)
  end

  it "rejects a negative redeem_points" do
    expect { described_class.new(redeem_points: -1) }.to raise_error(Dry::Struct::Error)
  end

  it "omits as_of by default and accepts an explicit nil" do
    expect(described_class.new({}).attributes.key?(:as_of)).to eq(false)
    expect { described_class.new(as_of: nil) }.not_to raise_error
  end

  it "accepts a present as_of for previewing a future/past-dated discount" do
    expect(described_class.new(as_of: "2026-06-01T00:00:00Z").as_of).to eq("2026-06-01T00:00:00Z")
  end
end
