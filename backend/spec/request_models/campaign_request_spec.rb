require "rails_helper"

RSpec.describe CampaignRequest do
  it "accepts just a required name, defaulting enabled to true" do
    record = described_class.new(name: "Summer Sale")
    expect(record.enabled).to eq(true)
  end

  it "rejects a missing name" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty name" do
    expect { described_class.new(name: "") }.to raise_error(Dry::Struct::Error)
  end

  it "accepts an explicit enabled: false" do
    expect(described_class.new(name: "Summer Sale", enabled: false).enabled).to eq(false)
  end

  %i[valid_from valid_until].each do |field|
    it "omits #{field} by default and accepts an explicit nil" do
      expect(described_class.new(name: "Summer Sale").attributes.key?(field)).to eq(false)
      expect { described_class.new(name: "Summer Sale", field => nil) }.not_to raise_error
    end
  end
end
