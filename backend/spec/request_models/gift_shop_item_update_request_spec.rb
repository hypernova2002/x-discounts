require "rails_helper"

RSpec.describe GiftShopItemUpdateRequest do
  it "accepts an empty body (nothing to update)" do
    expect { described_class.new({}) }.not_to raise_error
  end

  it "omits name when not sent, rejects an empty name, and rejects an explicit nil name" do
    expect(described_class.new({}).attributes.key?(:name)).to eq(false)
    expect { described_class.new(name: "") }.to raise_error(Dry::Struct::Error)
    expect { described_class.new(name: nil) }.to raise_error(Dry::Struct::Error)
  end

  it "omits description when not sent and accepts an explicit nil (clearing it)" do
    expect(described_class.new({}).attributes.key?(:description)).to eq(false)
    expect { described_class.new(description: nil) }.not_to raise_error
  end

  it "omits points_cost when not sent" do
    expect(described_class.new({}).attributes.key?(:points_cost)).to eq(false)
  end

  it "rejects an explicit nil points_cost (not nullable, unlike stock)" do
    expect { described_class.new(points_cost: nil) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a zero points_cost" do
    expect { described_class.new(points_cost: 0) }.to raise_error(Dry::Struct::Error)
  end

  it "accepts a positive points_cost" do
    expect(described_class.new(points_cost: 50).points_cost).to eq(50)
  end

  it "omits stock when not sent and accepts an explicit nil (unlimited)" do
    expect(described_class.new({}).attributes.key?(:stock)).to eq(false)
    expect { described_class.new(stock: nil) }.not_to raise_error
  end

  it "accepts a zero stock (sold out)" do
    expect(described_class.new(stock: 0).stock).to eq(0)
  end

  it "rejects a negative stock" do
    expect { described_class.new(stock: -1) }.to raise_error(Dry::Struct::Error)
  end

  it "omits enabled when not sent" do
    expect(described_class.new({}).attributes.key?(:enabled)).to eq(false)
  end

  it "rejects an explicit nil enabled (not nullable)" do
    expect { described_class.new(enabled: nil) }.to raise_error(Dry::Struct::Error)
  end
end
