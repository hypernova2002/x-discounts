require "rails_helper"

RSpec.describe UserResource do
  it "renders the user's fields" do
    user = create(:user, name: "Jane Doe", email: "jane@example.com")
    hash = described_class.new(user).to_h

    expect(hash["id"]).to eq(user.public_id)
    expect(hash["name"]).to eq("Jane Doe")
    expect(hash["email"]).to eq("jane@example.com")
    expect(hash["otp_enabled"]).to eq(false)
  end
end
