require "rails_helper"

RSpec.describe FixedAmountOffConfigRequest do
  let(:valid_attrs) { { amount: 10, currency: "USD" } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  it "accepts a float amount" do
    expect { described_class.new(valid_attrs.merge(amount: 9.99)) }.not_to raise_error
  end

  it "rejects a zero amount" do
    expect { described_class.new(valid_attrs.merge(amount: 0)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a negative amount" do
    expect { described_class.new(valid_attrs.merge(amount: -1)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing amount" do
    expect { described_class.new(valid_attrs.except(:amount)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing currency" do
    expect { described_class.new(valid_attrs.except(:currency)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty currency" do
    expect { described_class.new(valid_attrs.merge(currency: "")) }.to raise_error(Dry::Struct::Error)
  end
end
