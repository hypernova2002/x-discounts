require "rails_helper"

RSpec.describe OtpChallenge do
  let(:user) { create(:user) }

  it "persists a challenge with a digest, not the raw token, with a TTL expiry" do
    challenge = described_class.create_for(user: user)

    expect(challenge.token_digest).to eq(described_class.digest(challenge.raw_token))
    expect(challenge.expires_at).to be_within(5.seconds).of(Time.now.utc + OtpChallenge::TTL)
  end

  describe ".authenticate" do
    it "returns the challenge for a valid token" do
      challenge = described_class.create_for(user: user)
      found = described_class.authenticate(challenge.raw_token)
      expect(found.id).to eq(challenge.id)
    end

    it "returns nil for a nil token" do
      expect(described_class.authenticate(nil)).to be_nil
    end

    it "returns nil for an unknown token" do
      expect(described_class.authenticate("otpc_bogus")).to be_nil
    end

    it "returns nil for an expired token" do
      challenge = described_class.create_for(user: user)
      challenge.update(expires_at: 1.minute.ago)
      expect(described_class.authenticate(challenge.raw_token)).to be_nil
    end
  end

  describe "#consume!" do
    it "destroys the challenge" do
      challenge = described_class.create_for(user: user)
      challenge.consume!
      expect(OtpChallenge[challenge.id]).to be_nil
    end
  end
end
