require "rails_helper"

RSpec.describe PointsPerCurrencyConfigRequest do
  it "accepts a positive rate" do
    expect { described_class.new(rate: 1.5) }.not_to raise_error
  end

  it "rejects a zero rate" do
    expect { described_class.new(rate: 0) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a negative rate" do
    expect { described_class.new(rate: -1) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing rate" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end
end
