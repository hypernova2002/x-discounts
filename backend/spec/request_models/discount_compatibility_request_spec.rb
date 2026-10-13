require "rails_helper"

RSpec.describe DiscountCompatibilityRequest do
  it "accepts a valid compatible_discount_id" do
    expect { described_class.new(compatible_discount_id: "disc_abc123") }.not_to raise_error
  end

  it "rejects a missing compatible_discount_id" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty compatible_discount_id" do
    expect { described_class.new(compatible_discount_id: "") }.to raise_error(Dry::Struct::Error)
  end
end
