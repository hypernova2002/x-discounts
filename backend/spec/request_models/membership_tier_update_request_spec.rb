require "rails_helper"

RSpec.describe MembershipTierUpdateRequest do
  let(:condition) { { entity: "customer", key: "total_spent", operator: "gte", value: 1000 } }

  it "accepts an empty body (nothing to update)" do
    expect { described_class.new({}) }.not_to raise_error
  end

  it "omits name when not sent, rejects an explicit nil name, and rejects an empty name" do
    expect(described_class.new({}).attributes.key?(:name)).to eq(false)
    expect { described_class.new(name: nil) }.to raise_error(Dry::Struct::Error)
    expect { described_class.new(name: "") }.to raise_error(Dry::Struct::Error)
  end

  it "omits rank when not sent and rejects an explicit nil rank (not nullable)" do
    expect(described_class.new({}).attributes.key?(:rank)).to eq(false)
    expect { described_class.new(rank: nil) }.to raise_error(Dry::Struct::Error)
  end

  it "accepts a present rank" do
    expect(described_class.new(rank: 3).rank).to eq(3)
  end

  it "omits requirements_condition when not sent and accepts an explicit nil (opting out of auto-assignment)" do
    expect(described_class.new({}).attributes.key?(:requirements_condition)).to eq(false)
    expect { described_class.new(requirements_condition: nil) }.not_to raise_error
  end

  it "accepts a present requirements_condition" do
    record = described_class.new(requirements_condition: condition)
    expect(record.requirements_condition).to be_a(ConditionNode)
  end

  it "omits grace_period_days when not sent and accepts an explicit nil (clearing it)" do
    expect(described_class.new({}).attributes.key?(:grace_period_days)).to eq(false)
    expect { described_class.new(grace_period_days: nil) }.not_to raise_error
  end

  it "rejects a zero grace_period_days" do
    expect { described_class.new(grace_period_days: 0) }.to raise_error(Dry::Struct::Error)
  end
end
