require "rails_helper"

RSpec.describe Campaigns::UpdateService do
  let(:campaign) { create(:campaign, name: "Old Name", enabled: true, archived: false) }

  it "updates only name when only name is sent" do
    request = CampaignUpdateRequest.new(name: "New Name")
    updated = described_class.new(campaign: campaign, request: request).call
    expect(updated.name).to eq("New Name")
    expect(updated.enabled).to eq(true)
  end

  it "updates only enabled when only enabled is sent" do
    request = CampaignUpdateRequest.new(enabled: false)
    updated = described_class.new(campaign: campaign, request: request).call
    expect(updated.enabled).to eq(false)
    expect(updated.name).to eq("Old Name")
  end

  it "updates only archived when only archived is sent" do
    request = CampaignUpdateRequest.new(archived: true)
    updated = described_class.new(campaign: campaign, request: request).call
    expect(updated.archived).to eq(true)
  end

  it "updates only valid_from when only valid_from is sent" do
    request = CampaignUpdateRequest.new(valid_from: "2026-01-01T00:00:00Z")
    updated = described_class.new(campaign: campaign, request: request).call
    expect(updated.valid_from).to eq(Time.parse("2026-01-01T00:00:00Z"))
  end

  it "updates only valid_until when only valid_until is sent" do
    request = CampaignUpdateRequest.new(valid_until: "2026-12-31T00:00:00Z")
    updated = described_class.new(campaign: campaign, request: request).call
    expect(updated.valid_until).to eq(Time.parse("2026-12-31T00:00:00Z"))
  end

  it "leaves every field untouched when the request is empty" do
    request = CampaignUpdateRequest.new({})
    updated = described_class.new(campaign: campaign, request: request).call
    expect(updated.name).to eq("Old Name")
    expect(updated.enabled).to eq(true)
    expect(updated.archived).to eq(false)
  end
end
