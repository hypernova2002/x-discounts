require "rails_helper"

RSpec.describe Discounts::UpdateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }

  it "dispatches a PromotionDiscountUpdateRequest to Promotions::UpdateService" do
    discount = create(:discount, project: project, campaign: campaign, kind: "promotion", name: "Old Name",
                                  kind_config: { active_from: "2026-01-01T00:00:00Z" })
    request = PromotionDiscountUpdateRequest.new(name: "New Name")

    updated = described_class.new(discount: discount, request: request).call

    expect(updated.name).to eq("New Name")
    expect(updated.kind).to eq("promotion")
  end

  it "dispatches a CouponDiscountUpdateRequest to Coupons::UpdateService" do
    discount = create(:discount, project: project, campaign: campaign, kind: "coupon", name: "Old Name")
    request = CouponDiscountUpdateRequest.new(name: "New Name")

    updated = described_class.new(discount: discount, request: request).call

    expect(updated.name).to eq("New Name")
    expect(updated.kind).to eq("coupon")
  end

  it "dispatches a LoyaltyDiscountUpdateRequest to Loyalties::UpdateService" do
    discount = create(:discount, project: project, campaign: campaign, kind: "loyalty", name: "Old Name",
                                  kind_config: { active_from: "2026-01-01T00:00:00Z" })
    request = LoyaltyDiscountUpdateRequest.new(name: "New Name")

    updated = described_class.new(discount: discount, request: request).call

    expect(updated.name).to eq("New Name")
    expect(updated.kind).to eq("loyalty")
  end
end
