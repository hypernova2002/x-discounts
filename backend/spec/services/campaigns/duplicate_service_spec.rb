require "rails_helper"

RSpec.describe Campaigns::DuplicateService do
  let(:project) { create(:project) }
  let(:campaign) do
    create(:campaign, project: project, name: "Summer Sale", enabled: false,
                       valid_from: "2026-06-01T00:00:00Z", valid_until: "2026-08-31T00:00:00Z")
  end

  it "copies the campaign's own fields with a 'Copy of' name prefix" do
    duplicate = described_class.new(campaign: campaign).call

    expect(duplicate.name).to eq("Copy of Summer Sale")
    expect(duplicate.enabled).to eq(false)
    expect(duplicate.valid_from).to eq(Time.parse("2026-06-01T00:00:00Z"))
    expect(duplicate.valid_until).to eq(Time.parse("2026-08-31T00:00:00Z"))
  end

  it "doesn't append a collision suffix on a second duplicate (no unique-name constraint)" do
    described_class.new(campaign: campaign).call
    second = described_class.new(campaign: campaign).call
    expect(second.name).to eq("Copy of Summer Sale")
  end

  it "cascades to duplicate every discount under the campaign, pointed at the new campaign" do
    discount = create(:discount, project: project, campaign: campaign, name: "10% Off", key: "ten-off")
    create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })

    duplicate = described_class.new(campaign: campaign).call

    expect(duplicate.discounts_dataset.count).to eq(1)
    duplicated_discount = duplicate.discounts_dataset.first
    expect(duplicated_discount.campaign_id).to eq(duplicate.id)
    expect(duplicated_discount.name).to eq("Copy of 10% Off")
    expect(duplicated_discount.discount_effects.size).to eq(1)
  end

  it "leaves the original campaign's discounts pointed at the original campaign" do
    discount = create(:discount, project: project, campaign: campaign)
    described_class.new(campaign: campaign).call
    expect(discount.reload.campaign_id).to eq(campaign.id)
  end
end
