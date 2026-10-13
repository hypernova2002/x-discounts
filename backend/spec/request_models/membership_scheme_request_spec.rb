require "rails_helper"

RSpec.describe MembershipSchemeRequest do
  it "accepts a valid name" do
    expect { described_class.new(name: "VIP Tiers") }.not_to raise_error
  end

  it "rejects a missing name" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty name" do
    expect { described_class.new(name: "") }.to raise_error(Dry::Struct::Error)
  end
end
