# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoyaltyPointLots::BulkStatsService do
  describe "#call" do
    it "computes points_remaining as points plus the sum of ledger deltas, per lot" do
      lot = create(:loyalty_point_lot, points: 100)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "spend", delta: -30)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "spend", delta: -10)
      untouched_lot = create(:loyalty_point_lot, points: 50)

      stats = described_class.new([lot, untouched_lot]).call

      expect(stats.points_remaining[lot.id]).to eq(60)
      expect(stats.points_remaining[untouched_lot.id]).to eq(50)
    end

    it "reports cancelled for a lot with a clawback entry, regardless of expiry" do
      lot = create(:loyalty_point_lot, expires_at: Time.now.utc + 86_400)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "clawback", order_discount: create(:order_discount, kind: "loyalty"))

      stats = described_class.new([lot]).call

      expect(stats.statuses[lot.id]).to eq("cancelled")
    end

    it "reports expired for a lot past its expires_at with no clawback" do
      lot = create(:loyalty_point_lot, expires_at: Time.now.utc - 86_400)

      stats = described_class.new([lot]).call

      expect(stats.statuses[lot.id]).to eq("expired")
    end

    it "reports active for a lot with no clawback and no expiry in the past" do
      lot = create(:loyalty_point_lot, expires_at: nil)

      stats = described_class.new([lot]).call

      expect(stats.statuses[lot.id]).to eq("active")
    end

    it "returns empty maps for an empty batch" do
      stats = described_class.new([]).call

      expect(stats.points_remaining).to eq({})
      expect(stats.statuses).to eq({})
    end
  end
end
