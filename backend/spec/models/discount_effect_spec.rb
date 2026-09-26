require "rails_helper"

RSpec.describe DiscountEffect do
  let(:promotion) { create(:discount, kind: "promotion") }
  let(:loyalty_discount) { create(:discount, kind: "loyalty") }
  let(:line_item_condition) { { entity: "line_item", key: "sku", operator: "eq", value: "abc" } }

  describe "fixed_amount_off config" do
    let(:record) { create(:discount_effect, discount: promotion, effect_type: "fixed_amount_off", scope: "cart", config: { amount: 10, currency: "USD" }) }

    it "is valid with sane attributes" do
      expect(record).to be_valid
    end

    it "accepts a currency at the 255-character limit" do
      record.config = { amount: 10, currency: "a" * 255 }
      expect(record.valid?).to be true
    end

    it "rejects a currency over the 255-character limit" do
      record.config = { amount: 10, currency: "a" * 256 }
      record.valid?
      expect(Array(record.errors[:config])).not_to be_empty
    end

    it "accepts an amount at the 100000000 boundary" do
      record.config = { amount: 100_000_000, currency: "USD" }
      expect(record.valid?).to be true
    end

    it "rejects an amount over the 100000000 boundary" do
      record.config = { amount: 100_000_001, currency: "USD" }
      record.valid?
      expect(Array(record.errors[:config])).not_to be_empty
    end
  end

  describe "points_flat config" do
    let(:record) { create(:discount_effect, discount: loyalty_discount, effect_type: "points_flat", scope: "cart", config: { points: 100 }) }

    it "is valid with sane attributes" do
      expect(record).to be_valid
    end

    it "accepts points at the 10000000 boundary" do
      record.config = { points: 10_000_000 }
      expect(record.valid?).to be true
    end

    it "rejects points over the 10000000 boundary" do
      record.config = { points: 10_000_001 }
      record.valid?
      expect(Array(record.errors[:config])).not_to be_empty
    end
  end

  describe "points_per_item config" do
    let(:record) do
      create(:discount_effect, discount: loyalty_discount, effect_type: "points_per_item", scope: "line_item",
                               target_condition: line_item_condition, config: { points_per_item: 5 })
    end

    it "is valid with sane attributes" do
      expect(record).to be_valid
    end

    it "accepts points_per_item at the 10000000 boundary" do
      record.config = { points_per_item: 10_000_000 }
      expect(record.valid?).to be true
    end

    it "rejects points_per_item over the 10000000 boundary" do
      record.config = { points_per_item: 10_000_001 }
      record.valid?
      expect(Array(record.errors[:config])).not_to be_empty
    end
  end

  describe "free_item config" do
    let(:record) do
      create(:discount_effect, discount: promotion, effect_type: "free_item", scope: "line_item", target_condition: line_item_condition,
                               config: {
                                 buy_quantity: 2, get_quantity: 1, repeatable: true,
                                 buy_condition: line_item_condition, get_condition: line_item_condition
                               })
    end

    it "is valid with sane attributes" do
      expect(record).to be_valid
    end

    it "accepts buy_quantity at the 100000 boundary" do
      record.config = record.config.merge(buy_quantity: 100_000)
      expect(record.valid?).to be true
    end

    it "rejects buy_quantity over the 100000 boundary" do
      record.config = record.config.merge(buy_quantity: 100_001)
      record.valid?
      expect(Array(record.errors[:config])).not_to be_empty
    end

    it "rejects get_quantity over the 100000 boundary" do
      record.config = record.config.merge(get_quantity: 100_001)
      record.valid?
      expect(Array(record.errors[:config])).not_to be_empty
    end
  end
end
