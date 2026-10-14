require "rails_helper"

RSpec.describe MinimalUserResource do
  it "renders exactly id, name, email, locale, and otp_enabled, nothing else" do
    user = create(:user, name: "Jane Doe", email: "jane@example.com")
    hash = described_class.new(user).to_h

    expect(hash.keys).to contain_exactly("id", "name", "email", "locale", "otp_enabled")
    expect(hash["name"]).to eq("Jane Doe")
    expect(hash["email"]).to eq("jane@example.com")
  end
end
