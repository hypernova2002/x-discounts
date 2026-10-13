require "rails_helper"

RSpec.describe MembershipSchemes::CreateService do
  let(:project) { create(:project) }

  it "creates a scheme with the given name" do
    request = MembershipSchemeRequest.new(name: "VIP Tiers")
    scheme = described_class.new(project: project, request: request).call

    expect(scheme).to be_a(MembershipScheme)
    expect(scheme.name).to eq("VIP Tiers")
    expect(scheme.project_id).to eq(project.id)
  end

  # The request model only enforces a non-empty name (min_size: 1) — a name over
  # the model's own 1000-char bound still reaches the service and must be caught
  # there, by the Sequel model's own validates_utf8_length.
  it "raises a ValidationError for a name over the model's length bound" do
    request = MembershipSchemeRequest.new(name: "a" * 1001)

    expect { described_class.new(project: project, request: request).call }.to raise_error(ValidationError)
  end
end
