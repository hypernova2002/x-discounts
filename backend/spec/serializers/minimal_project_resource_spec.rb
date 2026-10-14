require "rails_helper"

RSpec.describe MinimalProjectResource do
  it "renders exactly id, name, timezone, and currency, nothing else" do
    project = create(:project, name: "Acme", timezone: "America/New_York", currency: "EUR")
    hash = described_class.new(project).to_h

    expect(hash.keys).to contain_exactly("id", "name", "timezone", "currency")
    expect(hash["name"]).to eq("Acme")
    expect(hash["timezone"]).to eq("America/New_York")
    expect(hash["currency"]).to eq("EUR")
  end
end
