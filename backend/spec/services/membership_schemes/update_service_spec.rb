require "rails_helper"

RSpec.describe MembershipSchemes::UpdateService do
  let(:scheme) { create(:membership_scheme, name: "Old Name") }

  it "updates the name when the request includes it" do
    request = MembershipSchemeUpdateRequest.new(name: "New Name")
    updated = described_class.new(scheme: scheme, request: request).call
    expect(updated.name).to eq("New Name")
  end

  it "leaves the name untouched when the request is empty" do
    request = MembershipSchemeUpdateRequest.new({})
    updated = described_class.new(scheme: scheme, request: request).call
    expect(updated.name).to eq("Old Name")
  end

  it "raises a ValidationError for a name over the model's length bound" do
    request = MembershipSchemeUpdateRequest.new(name: "a" * 1001)
    expect { described_class.new(scheme: scheme, request: request).call }.to raise_error(ValidationError)
  end
end
