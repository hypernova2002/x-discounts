require "rails_helper"

RSpec.describe CampaignSummaryResource do
  it "omits discount_summary by default" do
    campaign = create(:campaign)
    expect(described_class.new(campaign).to_h).not_to have_key("discount_summary")
  end

  it "includes discount_summary when requested" do
    campaign = create(:campaign)
    create(:discount, campaign: campaign, kind: "promotion")

    hash = described_class.new(campaign, params: { includes: ["discount_summary"] }).to_h

    expect(hash["discount_summary"]).to eq(campaign.discount_summary)
  end
end
