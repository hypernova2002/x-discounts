require "rails_helper"

RSpec.describe ExportResource do
  it "renders the export's plain fields" do
    export = create(:export, export_type: "campaigns", status: "completed")
    hash = described_class.new(export).to_h

    expect(hash["id"]).to eq(export.public_id)
    expect(hash["export_type"]).to eq("campaigns")
    expect(hash["status"]).to eq("completed")
  end

  it "omits requested_by by default" do
    export = create(:export)
    expect(described_class.new(export).to_h).not_to have_key("requested_by")
  end

  it "includes requested_by as the user's name when requested" do
    user = create(:user, name: "Jane Doe")
    export = create(:export, user: user)
    hash = described_class.new(export, params: { includes: ["requested_by"] }).to_h
    expect(hash["requested_by"]).to eq("Jane Doe")
  end

  # requested_by's `user.email` fallback isn't reachable through valid data — User's
  # own model validation requires `name`, so a persisted user always has one.
end
