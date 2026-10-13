require "rails_helper"

RSpec.describe Loyalties::UpdateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:discount) do
    create(:discount, project: project, campaign: campaign, kind: "loyalty", name: "Old Name",
                       kind_config: { active_from: "2026-01-01T00:00:00Z", points_expire_after_days: 30 })
  end

  it "updates name only when the request includes it" do
    request = LoyaltyDiscountUpdateRequest.new(name: "New Name")
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.name).to eq("New Name")
  end

  it "leaves kind_config untouched when the request doesn't include loyalty:" do
    request = LoyaltyDiscountUpdateRequest.new(name: "New Name")
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.points_expire_after_days).to eq(30)
  end

  it "rebuilds kind_config when the request includes loyalty:" do
    request = LoyaltyDiscountUpdateRequest.new(loyalty: { active_from: "2026-01-01T00:00:00Z", points_expire_after_days: 60 })
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.points_expire_after_days).to eq(60)
  end

  it "destroys and recreates effects when the request includes effects:" do
    create(:discount_effect, discount: discount, effect_type: "points_flat", scope: "cart", config: { points: 10 })
    old_id = discount.discount_effects.first.id

    request = LoyaltyDiscountUpdateRequest.new(effects: [{ effect_type: "points_flat", scope: "cart", config: { points: 20 } }])
    updated = described_class.new(discount: discount, request: request).call

    expect(updated.discount_effects.size).to eq(1)
    expect(DiscountEffect[old_id]).to be_nil
  end

  it "raises a ValidationError on a model validation failure" do
    request = LoyaltyDiscountUpdateRequest.new(name: "a" * 1001)
    expect { described_class.new(discount: discount, request: request).call }.to raise_error(ValidationError)
  end
end
