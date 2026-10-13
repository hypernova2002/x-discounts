require "rails_helper"

RSpec.describe DiscountEffectRequest do
  let(:valid_attrs) { { effect_type: "percentage_off", scope: "cart", config: { percentage: 10 } } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  DiscountEffect::EFFECT_TYPES.each do |effect_type|
    it "accepts the #{effect_type} effect_type" do
      expect { described_class.new(valid_attrs.merge(effect_type: effect_type, config: {})) }.not_to raise_error
    end
  end

  it "rejects an effect_type outside DiscountEffect::EFFECT_TYPES" do
    expect { described_class.new(valid_attrs.merge(effect_type: "buy_one_get_two")) }.to raise_error(Dry::Struct::Error)
  end

  DiscountEffect::SCOPES.each do |scope|
    it "accepts the #{scope} scope" do
      expect { described_class.new(valid_attrs.merge(scope: scope)) }.not_to raise_error
    end
  end

  it "rejects a scope outside DiscountEffect::SCOPES" do
    expect { described_class.new(valid_attrs.merge(scope: "order")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing config" do
    expect { described_class.new(valid_attrs.except(:config)) }.to raise_error(Dry::Struct::Error)
  end

  it "omits target_condition by default and accepts a present one" do
    expect(described_class.new(valid_attrs).attributes.key?(:target_condition)).to eq(false)
    condition = { entity: "line_item", key: "sku", operator: "eq", value: "X" }
    record = described_class.new(valid_attrs.merge(target_condition: condition))
    expect(record.target_condition).to be_a(ConditionNode)
  end

  describe "#typed_config" do
    {
      "percentage_off" => [{ percentage: 10 }, { percentage: 150 }, PercentageOffConfigRequest],
      "fixed_amount_off" => [{ amount: 5, currency: "USD" }, { amount: -5, currency: "USD" }, FixedAmountOffConfigRequest],
      "points_per_currency" => [{ rate: 1.5 }, { rate: 0 }, PointsPerCurrencyConfigRequest],
      "points_flat" => [{ points: 50 }, { points: 0 }, PointsFlatConfigRequest],
      "points_per_item" => [{ points_per_item: 10 }, { points_per_item: 0 }, PointsPerItemConfigRequest],
      "points_multiplier" => [{ multiplier: 2 }, { multiplier: 1 }, PointsMultiplierConfigRequest]
    }.each do |effect_type, (valid_config, invalid_config, config_class)|
      it "dispatches #{effect_type} to #{config_class}" do
        record = described_class.new(effect_type: effect_type, scope: "cart", config: valid_config)
        expect(record.typed_config).to be_a(config_class)
      end

      it "raises when #{effect_type}'s config fails #{config_class}'s own validation" do
        record = described_class.new(effect_type: effect_type, scope: "cart", config: invalid_config)
        expect { record.typed_config }.to raise_error(Dry::Struct::Error)
      end
    end

    it "dispatches free_item to FreeItemConfigRequest" do
      condition = { entity: "cart", key: "quantity", operator: "gte", value: 1 }
      config = { buy_quantity: 2, get_quantity: 1, repeatable: true, buy_condition: condition, get_condition: condition }
      record = described_class.new(effect_type: "free_item", scope: "cart", config: config)
      expect(record.typed_config).to be_a(FreeItemConfigRequest)
    end

    it "raises when free_item's config is missing a required field" do
      record = described_class.new(effect_type: "free_item", scope: "cart", config: { buy_quantity: 2 })
      expect { record.typed_config }.to raise_error(Dry::Struct::Error)
    end
  end
end
