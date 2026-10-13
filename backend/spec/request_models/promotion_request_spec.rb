require "rails_helper"

RSpec.describe PromotionRequest do
  it "accepts just the required active_from" do
    expect { described_class.new(active_from: "2026-01-01T00:00:00Z") }.not_to raise_error
  end

  it "rejects a missing active_from" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "omits active_until by default and accepts an explicit nil" do
    record = described_class.new(active_from: "2026-01-01T00:00:00Z")
    expect(record.attributes.key?(:active_until)).to eq(false)
    expect { described_class.new(active_from: "2026-01-01T00:00:00Z", active_until: nil) }.not_to raise_error
  end

  it "accepts a present active_until" do
    record = described_class.new(active_from: "2026-01-01T00:00:00Z", active_until: "2027-01-01T00:00:00Z")
    expect(record.active_until).to eq("2027-01-01T00:00:00Z")
  end
end
