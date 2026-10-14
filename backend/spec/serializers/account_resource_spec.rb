require "rails_helper"

RSpec.describe AccountResource do
  it "renders the account's fields" do
    account = create(:account, name: "Acme", otp_required: true)
    hash = described_class.new(account).to_h

    expect(hash["id"]).to eq(account.public_id)
    expect(hash["name"]).to eq("Acme")
    expect(hash["otp_required"]).to eq(true)
  end
end
