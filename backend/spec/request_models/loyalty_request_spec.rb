require "rails_helper"

RSpec.describe LoyaltyRequest do
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

  it "accepts points_expire_after_days at a valid positive value" do
    record = described_class.new(active_from: "2026-01-01T00:00:00Z", points_expire_after_days: 30)
    expect(record.points_expire_after_days).to eq(30)
  end

  it "rejects a zero points_expire_after_days" do
    expect { described_class.new(active_from: "2026-01-01T00:00:00Z", points_expire_after_days: 0) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a negative points_expire_after_days" do
    expect { described_class.new(active_from: "2026-01-01T00:00:00Z", points_expire_after_days: -1) }.to raise_error(Dry::Struct::Error)
  end

  it "omits points_expire_after_days by default and accepts an explicit nil (never expires)" do
    record = described_class.new(active_from: "2026-01-01T00:00:00Z")
    expect(record.attributes.key?(:points_expire_after_days)).to eq(false)
    expect { described_class.new(active_from: "2026-01-01T00:00:00Z", points_expire_after_days: nil) }.not_to raise_error
  end
end
