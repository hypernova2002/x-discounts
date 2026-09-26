require "rails_helper"

RSpec.describe CouponCodeGenerateRequest do
  it "accepts a count at the 10000 boundary" do
    expect { described_class.new(count: 10_000) }.not_to raise_error
  end

  it "rejects a count over the 10000 boundary" do
    expect { described_class.new(count: 10_001) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a count below 1" do
    expect { described_class.new(count: 0) }.to raise_error(Dry::Struct::Error)
  end
end
