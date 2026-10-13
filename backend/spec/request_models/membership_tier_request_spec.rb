require "rails_helper"

RSpec.describe MembershipTierRequest do
  let(:valid_attrs) { { name: "Gold", rank: 2 } }
  let(:condition) { { entity: "customer", key: "total_spent", operator: "gte", value: 1000 } }

  it "accepts just the required attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  it "rejects a missing name" do
    expect { described_class.new(valid_attrs.except(:name)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty name" do
    expect { described_class.new(valid_attrs.merge(name: "")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing rank" do
    expect { described_class.new(valid_attrs.except(:rank)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a non-integer rank" do
    expect { described_class.new(valid_attrs.merge(rank: "two")) }.to raise_error(Dry::Struct::Error)
  end

  it "omits requirements_condition by default (never auto-assigned) and accepts an explicit nil" do
    record = described_class.new(valid_attrs)
    expect(record.attributes.key?(:requirements_condition)).to eq(false)
    expect { described_class.new(valid_attrs.merge(requirements_condition: nil)) }.not_to raise_error
  end

  it "accepts a present requirements_condition" do
    record = described_class.new(valid_attrs.merge(requirements_condition: condition))
    expect(record.requirements_condition).to be_a(ConditionNode)
  end

  it "omits grace_period_days by default (demotion applies immediately) and accepts an explicit nil" do
    record = described_class.new(valid_attrs)
    expect(record.attributes.key?(:grace_period_days)).to eq(false)
    expect { described_class.new(valid_attrs.merge(grace_period_days: nil)) }.not_to raise_error
  end

  it "rejects a zero grace_period_days" do
    expect { described_class.new(valid_attrs.merge(grace_period_days: 0)) }.to raise_error(Dry::Struct::Error)
  end
end
