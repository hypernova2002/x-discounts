require "rails_helper"

RSpec.describe ProjectResource do
  it "renders the project's fields" do
    project = create(:project, name: "Acme", timezone: "America/New_York", currency: "EUR")
    hash = described_class.new(project).to_h

    expect(hash["id"]).to eq(project.public_id)
    expect(hash["name"]).to eq("Acme")
    expect(hash["timezone"]).to eq("America/New_York")
    expect(hash["currency"]).to eq("EUR")
  end
end
