require "rails_helper"

RSpec.describe Loyalties::CreateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }

  def build_request(**overrides)
    LoyaltyDiscountRequest.new({ name: "Earn Points", campaign_id: campaign.public_id, loyalty: { active_from: "2026-01-01T00:00:00Z" } }.merge(overrides))
  end

  it "builds a loyalty-kind discount with the request's fields" do
    discount = described_class.new(project: project, request: build_request, campaign: campaign).call
    expect(discount.kind).to eq("loyalty")
    expect(discount.name).to eq("Earn Points")
  end

  it "folds the loyalty sub-request's dates and points_expire_after_days into kind_config" do
    request = build_request(loyalty: { active_from: "2026-01-01T00:00:00Z", active_until: "2026-12-31T00:00:00Z", points_expire_after_days: 90 })
    discount = described_class.new(project: project, request: request, campaign: campaign).call

    expect(discount.active_from).to eq(Time.parse("2026-01-01T00:00:00Z"))
    expect(discount.active_until).to eq(Time.parse("2026-12-31T00:00:00Z"))
    expect(discount.points_expire_after_days).to eq(90)
  end

  it "generates a key from name when omitted" do
    discount = described_class.new(project: project, request: build_request(name: "Points Program"), campaign: campaign).call
    expect(discount.key).to eq("points-program")
  end

  it "saves the requested effects onto the discount" do
    request = build_request(effects: [{ effect_type: "points_flat", scope: "cart", config: { points: 50 } }])
    discount = described_class.new(project: project, request: request, campaign: campaign).call
    expect(discount.discount_effects.size).to eq(1)
  end

  it "raises a ValidationError when the key collides with an existing discount in the project" do
    create(:discount, project: project, campaign: campaign, key: "taken")
    expect { described_class.new(project: project, request: build_request(key: "taken"), campaign: campaign).call }.to raise_error(ValidationError)
  end
end
