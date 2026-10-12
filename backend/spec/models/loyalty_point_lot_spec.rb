require "rails_helper"

RSpec.describe LoyaltyPointLot do
  let(:record) { create(:loyalty_point_lot) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a bounded numeric field", :points, min: 0, max: 10_000_000, integer_only: true
  it_behaves_like "a utf8-length-bounded field", :reason, max: 10_000

  describe ".active_with_balance" do
    it "includes a plain lot with a positive balance" do
      lot = create(:loyalty_point_lot, points: 100)

      expect(described_class.active_with_balance(described_class.dataset)).to include(lot)
    end

    it "excludes a lot clawed back via a ledger entry" do
      lot = create(:loyalty_point_lot, points: 100)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "clawback", order_discount: create(:order_discount, kind: "loyalty"))

      expect(described_class.active_with_balance(described_class.dataset)).not_to include(lot)
    end

    it "excludes an expired lot" do
      lot = create(:loyalty_point_lot, points: 100, expires_at: Time.now.utc - 86_400)

      expect(described_class.active_with_balance(described_class.dataset)).not_to include(lot)
    end

    it "excludes a fully-spent (zero-balance) lot" do
      lot = create(:loyalty_point_lot, points: 100)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "spend", delta: -100)

      expect(described_class.active_with_balance(described_class.dataset)).not_to include(lot)
    end
  end
end
