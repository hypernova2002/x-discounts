require "rails_helper"

RSpec.describe DiscountEffectResource do
  it "renders the effect's fields" do
    effect = create(:discount_effect, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })
    hash = described_class.new(effect).to_h

    expect(hash["id"]).to eq(effect.public_id)
    expect(hash["effect_type"]).to eq("percentage_off")
    expect(hash["scope"]).to eq("cart")
    expect(hash["config"]).to eq({ "percentage" => 10 })
  end

  it "renders target_condition as nil when the effect has none" do
    effect = create(:discount_effect, scope: "cart")
    hash = described_class.new(effect).to_h
    expect(hash["target_condition"]).to be_nil
  end

  it "renders a present target_condition as a plain hash" do
    discount = create(:discount)
    effect = create(:discount_effect, discount: discount, scope: "line_item",
                                       target_condition: { entity: "line_item", key: "sku", operator: "eq", value: "X" })
    hash = described_class.new(effect).to_h

    expect(hash["target_condition"]).to eq({ "entity" => "line_item", "key" => "sku", "operator" => "eq", "value" => "X" })
  end
end
