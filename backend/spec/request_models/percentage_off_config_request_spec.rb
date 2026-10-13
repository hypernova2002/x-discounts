require "rails_helper"

RSpec.describe PercentageOffConfigRequest do
  it "accepts a percentage at the 100 boundary" do
    expect { described_class.new(percentage: 100) }.not_to raise_error
  end

  it "rejects a percentage over 100" do
    expect { described_class.new(percentage: 100.1) }.to raise_error(Dry::Struct::Error)
  end

  it "accepts a small positive percentage" do
    expect { described_class.new(percentage: 0.5) }.not_to raise_error
  end

  it "rejects a zero percentage" do
    expect { described_class.new(percentage: 0) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a negative percentage" do
    expect { described_class.new(percentage: -10) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing percentage" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end
end
