require "rails_helper"

RSpec.describe Promotions::CreateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }

  def build_request(**overrides)
    PromotionDiscountRequest.new({ name: "Sitewide 10%", campaign_id: campaign.public_id, promotion: { active_from: "2026-01-01T00:00:00Z" } }.merge(overrides))
  end

  it "builds a promotion-kind discount with the request's fields" do
    discount = described_class.new(project: project, request: build_request, campaign: campaign).call
    expect(discount.kind).to eq("promotion")
    expect(discount.name).to eq("Sitewide 10%")
  end

  it "folds the promotion sub-request's dates into kind_config" do
    request = build_request(promotion: { active_from: "2026-01-01T00:00:00Z", active_until: "2026-12-31T00:00:00Z" })
    discount = described_class.new(project: project, request: request, campaign: campaign).call
    expect(discount.active_from).to eq(Time.parse("2026-01-01T00:00:00Z"))
    expect(discount.active_until).to eq(Time.parse("2026-12-31T00:00:00Z"))
  end

  it "generates a key from name when omitted" do
    discount = described_class.new(project: project, request: build_request(name: "Summer Sale"), campaign: campaign).call
    expect(discount.key).to eq("summer-sale")
  end

  it "saves the requested effects onto the discount" do
    request = build_request(effects: [{ effect_type: "fixed_amount_off", scope: "cart", config: { amount: 5, currency: "USD" } }])
    discount = described_class.new(project: project, request: request, campaign: campaign).call
    expect(discount.discount_effects.size).to eq(1)
  end

  it "raises a ValidationError when the key collides with an existing discount in the project" do
    create(:discount, project: project, campaign: campaign, key: "taken")
    expect { described_class.new(project: project, request: build_request(key: "taken"), campaign: campaign).call }.to raise_error(ValidationError)
  end
end
