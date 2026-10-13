require "rails_helper"

RSpec.describe MembershipSchemeUpdateRequest do
  it "accepts an empty body (nothing to update)" do
    expect { described_class.new({}) }.not_to raise_error
  end

  it "omits name when not sent" do
    expect(described_class.new({}).attributes.key?(:name)).to eq(false)
  end

  it "rejects an explicit nil name (not nullable)" do
    expect { described_class.new(name: nil) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty name" do
    expect { described_class.new(name: "") }.to raise_error(Dry::Struct::Error)
  end

  it "accepts a present name" do
    expect(described_class.new(name: "Renamed").name).to eq("Renamed")
  end
end
