# frozen_string_literal: true

require "rails_helper"

RSpec.describe CampaignResource do
  it "omits discount_kinds by default, but keeps active always-on" do
    campaign = create(:campaign)

    hash = described_class.new(campaign).to_h

    expect(hash).not_to have_key("discount_kinds")
    expect(hash).to have_key("active")
  end

  it "falls back to a live per-campaign query when no bulk map is given" do
    campaign = create(:campaign)
    create(:discount, campaign: campaign, kind: "promotion")

    hash = described_class.new(campaign, params: { includes: ["discount_kinds"] }).to_h

    expect(hash["discount_kinds"]).to eq(["promotion"])
  end

  it "prefers a bulk-provided discount_kinds_by_campaign map over the live query" do
    campaign = create(:campaign)

    hash = described_class.new(campaign, params: { includes: ["discount_kinds"], discount_kinds_by_campaign: { campaign.id => %w[coupon loyalty] } }).to_h

    expect(hash["discount_kinds"]).to eq(%w[coupon loyalty])
  end
end
