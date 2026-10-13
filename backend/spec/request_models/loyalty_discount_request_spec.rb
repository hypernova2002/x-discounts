require "rails_helper"

RSpec.describe LoyaltyDiscountRequest do
  let(:valid_attrs) { { name: "Earn Points", campaign_id: "camp_1", loyalty: { active_from: "2026-01-01T00:00:00Z" } } }

  it "accepts just the required attributes" do
    record = described_class.new(valid_attrs)
    expect(record.stackable).to eq(false)
    expect(record.refundable).to eq(true)
    expect(record.enabled).to eq(true)
  end

  it "rejects a missing name" do
    expect { described_class.new(valid_attrs.except(:name)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing campaign_id" do
    expect { described_class.new(valid_attrs.except(:campaign_id)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing loyalty sub-struct" do
    expect { described_class.new(valid_attrs.except(:loyalty)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a loyalty sub-struct missing its own required active_from" do
    expect { described_class.new(valid_attrs.merge(loyalty: {})) }.to raise_error(Dry::Struct::Error)
  end

  it "builds loyalty as a LoyaltyRequest instance" do
    expect(described_class.new(valid_attrs).loyalty).to be_a(LoyaltyRequest)
  end

  it "omits key by default and rejects an empty key" do
    expect(described_class.new(valid_attrs).attributes.key?(:key)).to eq(false)
    expect { described_class.new(valid_attrs.merge(key: "")) }.to raise_error(Dry::Struct::Error)
  end

  it "omits eligibility_condition and effects by default" do
    record = described_class.new(valid_attrs)
    expect(record.attributes.key?(:eligibility_condition)).to eq(false)
    expect(record.attributes.key?(:effects)).to eq(false)
  end
end
