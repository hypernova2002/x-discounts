require "rails_helper"

RSpec.describe CustomerGrantPointsRequest do
  it "accepts valid attributes" do
    expect { described_class.new(points: 100) }.not_to raise_error
  end

  it "accepts a negative points value (claw-back grants are allowed)" do
    expect { described_class.new(points: -50) }.not_to raise_error
  end

  it "rejects a missing points" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a non-integer points value" do
    expect { described_class.new(points: 10.5) }.to raise_error(Dry::Struct::Error)
  end

  it "omits expires_at and reason by default" do
    record = described_class.new(points: 100)
    expect(record.attributes.key?(:expires_at)).to eq(false)
    expect(record.attributes.key?(:reason)).to eq(false)
  end

  it "accepts an explicit nil expires_at and reason" do
    expect { described_class.new(points: 100, expires_at: nil, reason: nil) }.not_to raise_error
  end

  it "accepts a present expires_at and reason" do
    record = described_class.new(points: 100, expires_at: "2027-01-01T00:00:00Z", reason: "goodwill")
    expect(record.expires_at).to eq("2027-01-01T00:00:00Z")
    expect(record.reason).to eq("goodwill")
  end
end
