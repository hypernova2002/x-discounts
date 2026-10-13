require "rails_helper"

RSpec.describe ProjectRequest do
  it "accepts just a required name" do
    expect { described_class.new(name: "Default") }.not_to raise_error
  end

  it "rejects a missing name" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty name" do
    expect { described_class.new(name: "") }.to raise_error(Dry::Struct::Error)
  end

  %i[timezone currency].each do |field|
    it "omits #{field} by default and accepts an explicit nil" do
      expect(described_class.new(name: "Default").attributes.key?(field)).to eq(false)
      expect { described_class.new(name: "Default", field => nil) }.not_to raise_error
    end
  end

  it "accepts an explicit timezone and currency" do
    record = described_class.new(name: "Default", timezone: "America/New_York", currency: "USD")
    expect(record.timezone).to eq("America/New_York")
    expect(record.currency).to eq("USD")
  end
end
