require "rails_helper"

RSpec.describe Campaigns::CreateService do
  let(:project) { create(:project) }

  it "creates a campaign with the given fields" do
    request = CampaignRequest.new(name: "Summer Sale", enabled: false, valid_from: "2026-06-01T00:00:00Z", valid_until: "2026-08-31T00:00:00Z")
    campaign = described_class.new(project: project, request: request).call

    expect(campaign.name).to eq("Summer Sale")
    expect(campaign.enabled).to eq(false)
    expect(campaign.valid_from).to eq(Time.parse("2026-06-01T00:00:00Z"))
    expect(campaign.project_id).to eq(project.id)
  end

  it "raises a ValidationError for a name over the model's length bound" do
    request = CampaignRequest.new(name: "a" * 1001)
    expect { described_class.new(project: project, request: request).call }.to raise_error(ValidationError)
  end
end
