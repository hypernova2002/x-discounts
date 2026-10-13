require "rails_helper"

RSpec.describe FreeItemConfigRequest do
  let(:condition) { { entity: "cart", key: "quantity", operator: "gte", value: 1 } }
  let(:valid_attrs) { { buy_quantity: 2, get_quantity: 1, repeatable: true, buy_condition: condition, get_condition: condition } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  it "rejects a zero buy_quantity" do
    expect { described_class.new(valid_attrs.merge(buy_quantity: 0)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a zero get_quantity" do
    expect { described_class.new(valid_attrs.merge(get_quantity: 0)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing repeatable" do
    expect { described_class.new(valid_attrs.except(:repeatable)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a non-boolean repeatable" do
    expect { described_class.new(valid_attrs.merge(repeatable: "yes")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing buy_condition" do
    expect { described_class.new(valid_attrs.except(:buy_condition)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing get_condition" do
    expect { described_class.new(valid_attrs.except(:get_condition)) }.to raise_error(Dry::Struct::Error)
  end

  it "builds buy_condition and get_condition as ConditionNode instances" do
    record = described_class.new(valid_attrs)
    expect(record.buy_condition).to be_a(ConditionNode)
    expect(record.get_condition).to be_a(ConditionNode)
  end
end
