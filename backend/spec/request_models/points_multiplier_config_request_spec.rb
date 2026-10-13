require "rails_helper"

RSpec.describe PointsMultiplierConfigRequest do
  it "accepts a multiplier above 1" do
    expect { described_class.new(multiplier: 1.5) }.not_to raise_error
  end

  it "rejects a multiplier at exactly 1 (must actually multiply)" do
    expect { described_class.new(multiplier: 1) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a multiplier below 1" do
    expect { described_class.new(multiplier: 0.5) }.to raise_error(Dry::Struct::Error)
  end

  it "accepts an integer multiplier above 1" do
    expect { described_class.new(multiplier: 2) }.not_to raise_error
  end

  it "rejects a missing multiplier" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end
end
