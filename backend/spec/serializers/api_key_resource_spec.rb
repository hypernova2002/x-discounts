require "rails_helper"

RSpec.describe ApiKeyResource do
  it "renders the key's plain fields" do
    key = create(:api_key, name: "CI key", role: "admin")
    hash = described_class.new(key).to_h

    expect(hash["id"]).to eq(key.public_id)
    expect(hash["name"]).to eq("CI key")
    expect(hash["role"]).to eq("admin")
  end

  it "omits user_id by default" do
    key = create(:api_key)
    expect(described_class.new(key).to_h).not_to have_key("user_id")
  end

  it "includes user_id when requested" do
    key = create(:api_key)
    hash = described_class.new(key, params: { includes: ["user_id"] }).to_h
    expect(hash["user_id"]).to eq(key.user.public_id)
  end

  it "omits token by default" do
    key = create(:api_key)
    expect(described_class.new(key).to_h).not_to have_key("token")
  end

  it "includes token only via params[:include_token], not the usual includes= mechanism" do
    key = create(:api_key)
    no_token_hash = described_class.new(key, params: { includes: ["token"] }).to_h
    expect(no_token_hash).not_to have_key("token")

    with_token_hash = described_class.new(key, params: { include_token: true }).to_h
    expect(with_token_hash["token"]).to eq(key.raw_token)
  end
end
