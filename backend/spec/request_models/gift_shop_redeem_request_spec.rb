require "rails_helper"

RSpec.describe GiftShopRedeemRequest do
  it "defaults quantity to 1" do
    record = described_class.new(customer_external_id: "cust-1")
    expect(record.quantity).to eq(1)
  end

  it "rejects a missing customer_external_id" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty customer_external_id" do
    expect { described_class.new(customer_external_id: "") }.to raise_error(Dry::Struct::Error)
  end

  it "accepts an explicit quantity" do
    expect(described_class.new(customer_external_id: "cust-1", quantity: 5).quantity).to eq(5)
  end

  it "rejects a zero quantity" do
    expect { described_class.new(customer_external_id: "cust-1", quantity: 0) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a negative quantity" do
    expect { described_class.new(customer_external_id: "cust-1", quantity: -1) }.to raise_error(Dry::Struct::Error)
  end
end
