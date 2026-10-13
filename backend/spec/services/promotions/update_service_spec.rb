require "rails_helper"

RSpec.describe Promotions::UpdateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:discount) do
    create(:discount, project: project, campaign: campaign, kind: "promotion", name: "Old Name",
                       kind_config: { active_from: "2026-01-01T00:00:00Z" })
  end

  it "updates name only when the request includes it" do
    request = PromotionDiscountUpdateRequest.new(name: "New Name")
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.name).to eq("New Name")
  end

  it "rebuilds kind_config only when the request includes promotion:" do
    request = PromotionDiscountUpdateRequest.new(name: "New Name")
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.kind_config["active_from"]).to eq("2026-01-01T00:00:00Z")
  end

  it "updates kind_config when the request includes promotion:" do
    request = PromotionDiscountUpdateRequest.new(promotion: { active_from: "2027-01-01T00:00:00Z" })
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.active_from).to eq(Time.parse("2027-01-01T00:00:00Z"))
  end

  it "destroys and recreates effects when the request includes effects:" do
    create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 5 })
    old_id = discount.discount_effects.first.id

    request = PromotionDiscountUpdateRequest.new(effects: [{ effect_type: "fixed_amount_off", scope: "cart", config: { amount: 10, currency: "USD" } }])
    updated = described_class.new(discount: discount, request: request).call

    expect(updated.discount_effects.size).to eq(1)
    expect(DiscountEffect[old_id]).to be_nil
  end

  it "leaves effects untouched when the request doesn't include effects:" do
    create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 5 })
    request = PromotionDiscountUpdateRequest.new(name: "New Name")
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.discount_effects.size).to eq(1)
  end

  it "raises a ValidationError on a model validation failure" do
    request = PromotionDiscountUpdateRequest.new(name: "a" * 1001)
    expect { described_class.new(discount: discount, request: request).call }.to raise_error(ValidationError)
  end
end
