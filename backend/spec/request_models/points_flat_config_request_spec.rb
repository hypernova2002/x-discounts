require "rails_helper"

RSpec.describe PointsFlatConfigRequest do
  it "accepts a positive points value" do
    expect { described_class.new(points: 50) }.not_to raise_error
  end

  it "rejects a zero points value" do
    expect { described_class.new(points: 0) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a negative points value" do
    expect { described_class.new(points: -1) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing points value" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a non-integer points value" do
    expect { described_class.new(points: 5.5) }.to raise_error(Dry::Struct::Error)
  end
end
