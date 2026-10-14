require "rails_helper"

RSpec.describe MinimalAccountResource do
  it "renders exactly id and name, nothing else" do
    account = create(:account, name: "Acme")
    hash = described_class.new(account).to_h

    expect(hash.keys).to contain_exactly("id", "name")
    expect(hash["name"]).to eq("Acme")
  end
end
