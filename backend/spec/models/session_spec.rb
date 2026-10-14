require "rails_helper"

RSpec.describe Session do
  let(:user) { create(:user) }

  describe ".create_for" do
    it "persists a session with a digest, not the raw token" do
      session = described_class.create_for(user: user)
      expect(session).to be_a(Session)
      expect(session.token_digest).to eq(described_class.digest(session.raw_token))
    end

    it "sets expires_at TTL days in the future" do
      session = described_class.create_for(user: user)
      expect(session.expires_at).to be_within(5.seconds).of(Time.now.utc + Session::TTL)
    end

    it "only exposes raw_token on the instance that just created it" do
      session = described_class.create_for(user: user)
      reloaded = Session[session.id]
      expect(reloaded.raw_token).to be_nil
    end
  end

  describe ".digest" do
    it "is a pure, deterministic SHA256 function" do
      expect(described_class.digest("sess_abc")).to eq(described_class.digest("sess_abc"))
      expect(described_class.digest("sess_abc")).not_to eq(described_class.digest("sess_xyz"))
    end
  end

  describe ".authenticate" do
    it "returns the session for a valid token and bumps last_used_at" do
      session = described_class.create_for(user: user)
      found = described_class.authenticate(session.raw_token)

      expect(found.id).to eq(session.id)
      expect(found.last_used_at).not_to be_nil
    end

    it "returns nil for an unknown token" do
      expect(described_class.authenticate("sess_bogus")).to be_nil
    end

    it "returns nil for an expired token" do
      session = described_class.create_for(user: user)
      session.update(expires_at: 1.minute.ago)

      expect(described_class.authenticate(session.raw_token)).to be_nil
    end
  end

  describe "#expired?" do
    it "is false before expires_at" do
      session = described_class.create_for(user: user)
      expect(session.expired?).to eq(false)
    end

    it "is true after expires_at" do
      session = described_class.create_for(user: user)
      session.expires_at = 1.minute.ago
      expect(session.expired?).to eq(true)
    end
  end
end
