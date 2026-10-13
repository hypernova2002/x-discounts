require "rails_helper"

RSpec.describe RefundRequest do
  it "accepts an empty body (refunds whatever's left)" do
    expect { described_class.new({}) }.not_to raise_error
  end

  it "accepts just amount_off" do
    expect(described_class.new(amount_off: 10).amount_off).to eq(10)
  end

  it "accepts just points" do
    expect(described_class.new(points: 50).points).to eq(50)
  end

  it "rejects a non-numeric amount_off" do
    expect { described_class.new(amount_off: "ten") }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a non-integer points" do
    expect { described_class.new(points: 10.5) }.to raise_error(Dry::Struct::Error)
  end

  it "omits reason by default and accepts an explicit nil" do
    expect(described_class.new({}).attributes.key?(:reason)).to eq(false)
    expect { described_class.new(reason: nil) }.not_to raise_error
  end

  it "accepts a present reason" do
    expect(described_class.new(reason: "goodwill").reason).to eq("goodwill")
  end
end
