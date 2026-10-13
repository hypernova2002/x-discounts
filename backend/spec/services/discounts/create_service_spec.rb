require "rails_helper"

RSpec.describe Discounts::CreateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }

  it "dispatches a PromotionDiscountRequest to Promotions::CreateService" do
    request = PromotionDiscountRequest.new(name: "Sitewide 10%", campaign_id: campaign.public_id, promotion: { active_from: "2026-01-01T00:00:00Z" })

    discount = described_class.new(project: project, request: request, campaign: campaign).call

    expect(discount).to be_a(Discount)
    expect(discount.kind).to eq("promotion")
    expect(discount.name).to eq("Sitewide 10%")
    expect(discount.exists?).to eq(true)
  end

  it "dispatches a CouponDiscountRequest to Coupons::CreateService" do
    request = CouponDiscountRequest.new(name: "Save 10", campaign_id: campaign.public_id, coupon: {})

    discount = described_class.new(project: project, request: request, campaign: campaign).call

    expect(discount.kind).to eq("coupon")
    expect(discount.exists?).to eq(true)
  end

  it "dispatches a LoyaltyDiscountRequest to Loyalties::CreateService" do
    request = LoyaltyDiscountRequest.new(name: "Earn Points", campaign_id: campaign.public_id, loyalty: { active_from: "2026-01-01T00:00:00Z" })

    discount = described_class.new(project: project, request: request, campaign: campaign).call

    expect(discount.kind).to eq("loyalty")
    expect(discount.exists?).to eq(true)
  end
end
