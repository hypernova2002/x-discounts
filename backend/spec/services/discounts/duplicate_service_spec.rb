require "rails_helper"

RSpec.describe Discounts::DuplicateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:discount) do
    create(:discount, project: project, campaign: campaign, kind: "promotion", key: "sale", name: "Sale",
                       stackable: true, refundable: false, enabled: true,
                       eligibility_condition: { entity: "cart", key: "total", operator: "gte", value: 10 },
                       kind_config: { active_from: "2026-01-01T00:00:00Z" },
                       max_redemptions: 100, max_redemptions_per_customer: 2, max_redemptions_per_day: 10,
                       max_redemption_amount: 500, max_redemption_amount_per_day: 50, max_redemption_amount_per_customer: 20)
  end

  it "copies the source discount's own fields" do
    duplicate = described_class.new(discount: discount).call

    expect(duplicate.kind).to eq("promotion")
    expect(duplicate.name).to eq("Copy of Sale")
    expect(duplicate.stackable).to eq(true)
    expect(duplicate.refundable).to eq(false)
    expect(duplicate.enabled).to eq(true)
    expect(duplicate.eligibility_condition.to_h).to eq(discount.eligibility_condition.to_h)
    expect(duplicate.kind_config.to_h).to eq(discount.kind_config.to_h)
    expect(duplicate.max_redemptions).to eq(100)
    expect(duplicate.max_redemptions_per_customer).to eq(2)
    expect(duplicate.max_redemptions_per_day).to eq(10)
    expect(duplicate.max_redemption_amount).to eq(500)
    expect(duplicate.max_redemption_amount_per_day).to eq(50)
    expect(duplicate.max_redemption_amount_per_customer).to eq(20)
  end

  it "keys the duplicate as <key>-copy" do
    duplicate = described_class.new(discount: discount).call
    expect(duplicate.key).to eq("sale-copy")
  end

  it "keys a second duplicate as <key>-copy-2" do
    described_class.new(discount: discount).call
    second = described_class.new(discount: discount).call
    expect(second.key).to eq("sale-copy-2")
  end

  it "copies every discount_effect" do
    create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })
    create(:discount_effect, discount: discount, effect_type: "fixed_amount_off", scope: "line_item",
                              target_condition: { entity: "line_item", key: "sku", operator: "eq", value: "X" }, config: { amount: 5, currency: "USD" })

    duplicate = described_class.new(discount: discount).call

    expect(duplicate.discount_effects.size).to eq(2)
    expect(duplicate.discount_effects.map(&:effect_type)).to contain_exactly("percentage_off", "fixed_amount_off")
    line_item_effect = duplicate.discount_effects.find { |e| e.scope == "line_item" }
    expect(line_item_effect.target_condition.to_h).to eq({ "entity" => "line_item", "key" => "sku", "operator" => "eq", "value" => "X" })
    expect(line_item_effect.config.to_h).to eq({ "amount" => 5, "currency" => "USD" })
  end

  it "does not copy coupon_codes" do
    coupon_discount = create(:discount, project: project, campaign: campaign, kind: "coupon")
    create(:coupon, discount: coupon_discount, project: project, code: "SAVE10")

    duplicate = described_class.new(discount: coupon_discount).call
    expect(duplicate.coupon_codes).to be_empty
  end

  it "does not copy discount_stacking_compatibilities" do
    other = create(:discount, project: project, campaign: campaign)
    DiscountStackingCompatibility.create(discount_id: discount.id, compatible_discount_id: other.id)

    duplicate = described_class.new(discount: discount).call
    expect(duplicate.discount_stacking_compatibilities).to be_empty
  end

  it "points the duplicate at the source's own campaign by default" do
    duplicate = described_class.new(discount: discount).call
    expect(duplicate.campaign_id).to eq(campaign.id)
  end

  it "points the duplicate at an explicitly given campaign" do
    other_campaign = create(:campaign, project: project)
    duplicate = described_class.new(discount: discount, campaign: other_campaign).call
    expect(duplicate.campaign_id).to eq(other_campaign.id)
  end
end
