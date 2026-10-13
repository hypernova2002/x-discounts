require "rails_helper"

RSpec.describe GiftShopItemRequest do
  let(:valid_attrs) { { name: "Mug", points_cost: 100 } }

  it "accepts just the required attributes" do
    record = described_class.new(valid_attrs)
    expect(record.enabled).to eq(true)
  end

  it "rejects a missing name" do
    expect { described_class.new(valid_attrs.except(:name)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty name" do
    expect { described_class.new(valid_attrs.merge(name: "")) }.to raise_error(Dry::Struct::Error)
  end

  it "omits description by default and accepts an explicit nil" do
    expect(described_class.new(valid_attrs).attributes.key?(:description)).to eq(false)
    expect { described_class.new(valid_attrs.merge(description: nil)) }.not_to raise_error
  end

  it "rejects a missing points_cost" do
    expect { described_class.new(valid_attrs.except(:points_cost)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a zero points_cost" do
    expect { described_class.new(valid_attrs.merge(points_cost: 0)) }.to raise_error(Dry::Struct::Error)
  end

  it "accepts a zero stock (sold out, not unlimited)" do
    expect { described_class.new(valid_attrs.merge(stock: 0)) }.not_to raise_error
  end

  it "rejects a negative stock" do
    expect { described_class.new(valid_attrs.merge(stock: -1)) }.to raise_error(Dry::Struct::Error)
  end

  it "omits stock by default and accepts an explicit nil (unlimited)" do
    expect(described_class.new(valid_attrs).attributes.key?(:stock)).to eq(false)
    expect { described_class.new(valid_attrs.merge(stock: nil)) }.not_to raise_error
  end

  it "defaults enabled to true and accepts an explicit false" do
    expect(described_class.new(valid_attrs).enabled).to eq(true)
    expect(described_class.new(valid_attrs.merge(enabled: false)).enabled).to eq(false)
  end
end
