require "rails_helper"

RSpec.describe Discount do
  let(:record) { create(:discount) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a utf8-length-bounded field", :key, max: 255
  it_behaves_like "a boolean-typed field", :stackable
  it_behaves_like "a boolean-typed field", :refundable
  it_behaves_like "a boolean-typed field", :enabled
  it_behaves_like "a bounded numeric field", :max_redemptions, min: 1, max: 1_000_000, integer_only: true
  it_behaves_like "a bounded numeric field", :max_redemptions_per_customer, min: 1, max: 1_000_000, integer_only: true
  it_behaves_like "a bounded numeric field", :max_redemptions_per_day, min: 1, max: 1_000_000, integer_only: true
  it_behaves_like "a bounded numeric field", :max_redemption_amount, min: 0, max: 100_000_000
  it_behaves_like "a bounded numeric field", :max_redemption_amount_per_day, min: 0, max: 100_000_000
  it_behaves_like "a bounded numeric field", :max_redemption_amount_per_customer, min: 0, max: 100_000_000

  describe "kind_config sub-fields" do
    it "accepts a design_html at the 10000-character limit" do
      record.kind_config = { "design_html" => "a" * 10_000 }
      record.valid?
      expect(Array(record.errors[:kind_config])).to be_empty
    end

    it "rejects a design_html over the 10000-character limit" do
      record.kind_config = { "design_html" => "a" * 10_001 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "rejects a design_image_filename over the 255-character limit" do
      record.kind_config = { "design_image_filename" => "a" * 256 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "rejects a design_image_content_type over the 255-character limit" do
      record.kind_config = { "design_image_content_type" => "a" * 256 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "accepts points_expire_after_days at the 10000 boundary" do
      record.kind_config = { "points_expire_after_days" => 10_000 }
      record.valid?
      expect(Array(record.errors[:kind_config])).to be_empty
    end

    it "rejects points_expire_after_days over 10000" do
      record.kind_config = { "points_expire_after_days" => 10_001 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "rejects a negative points_expire_after_days" do
      record.kind_config = { "points_expire_after_days" => -1 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "rejects a non-integer points_expire_after_days" do
      record.kind_config = { "points_expire_after_days" => 5.5 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end
  end

  describe "#redemption_count" do
    it "counts non-refunded order_discounts, excluding a coupon-refunded and a loyalty-clawed-back row" do
      discount = create(:discount, kind: "promotion")
      create(:order_discount, discount: discount, kind: "promotion")

      refunded = create(:order_discount, discount: discount, kind: "promotion")
      create(:discount_refund, order_discount: refunded)

      lot = create(:loyalty_point_lot)
      clawed_back = create(:order_discount, discount: discount, kind: "loyalty", loyalty_point_lot: lot)
      create(:loyalty_point_ledger_entry, loyalty_point_lot: lot, kind: "clawback", order_discount: clawed_back)

      expect(discount.redemption_count).to eq(1)
    end
  end

  describe ".ending_soon" do
    let(:now) { Time.utc(2026, 6, 1) }
    let(:soon) { now + (14 * 24 * 60 * 60) }

    it "includes a coupon discount whose valid_until falls just inside the window" do
      discount = create(:discount, kind: "coupon", kind_config: { valid_until: (now + 10 * 24 * 60 * 60).iso8601 })

      expect(described_class.ending_soon(described_class.dataset, from: now, to: soon)).to include(discount)
    end

    it "includes a promotion discount whose active_until falls just inside the window" do
      discount = create(:discount, kind: "promotion", kind_config: { active_until: (now + 10 * 24 * 60 * 60).iso8601 })

      expect(described_class.ending_soon(described_class.dataset, from: now, to: soon)).to include(discount)
    end

    it "excludes a discount ending after the window" do
      discount = create(:discount, kind: "promotion", kind_config: { active_until: (now + 30 * 24 * 60 * 60).iso8601 })

      expect(described_class.ending_soon(described_class.dataset, from: now, to: soon)).not_to include(discount)
    end

    it "excludes a discount with no end date" do
      discount = create(:discount, kind: "promotion", kind_config: {})

      expect(described_class.ending_soon(described_class.dataset, from: now, to: soon)).not_to include(discount)
    end

    it "does not match a coupon's valid_until against active_until's kind branch" do
      # A coupon discount's end date lives under valid_until, not active_until —
      # confirm the kind-branching doesn't accidentally cross-match.
      discount = create(:discount, kind: "coupon", kind_config: { active_until: (now + 10 * 24 * 60 * 60).iso8601 })

      expect(described_class.ending_soon(described_class.dataset, from: now, to: soon)).not_to include(discount)
    end
  end
end
