require "rails_helper"

RSpec.describe OrderCancelRequest do
  it "defaults refund to false" do
    expect(described_class.new({}).refund).to eq(false)
  end

  it "accepts an explicit refund: true" do
    expect(described_class.new(refund: true).refund).to eq(true)
  end

  it "rejects a non-boolean refund" do
    expect { described_class.new(refund: "yes") }.to raise_error(Dry::Struct::Error)
  end

  it "omits reason by default and accepts an explicit nil" do
    expect(described_class.new({}).attributes.key?(:reason)).to eq(false)
    expect { described_class.new(reason: nil) }.not_to raise_error
  end

  it "accepts a present reason" do
    expect(described_class.new(reason: "customer request").reason).to eq("customer request")
  end
end
