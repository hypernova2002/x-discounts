require "rails_helper"

RSpec.describe PointsPerItemConfigRequest do
  it "accepts a positive points_per_item" do
    expect { described_class.new(points_per_item: 10) }.not_to raise_error
  end

  it "rejects a zero points_per_item" do
    expect { described_class.new(points_per_item: 0) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a negative points_per_item" do
    expect { described_class.new(points_per_item: -1) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing points_per_item" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end
end
