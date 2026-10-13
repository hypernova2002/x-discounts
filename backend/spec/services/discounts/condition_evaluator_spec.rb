require "rails_helper"

RSpec.describe Discounts::ConditionEvaluator do
  let(:evaluator) { described_class.new(cart: cart, customer: customer, line_item: line_item, line_items: line_items, membership_tier: membership_tier) }
  let(:cart) { {} }
  let(:customer) { {} }
  let(:line_item) { nil }
  let(:line_items) { [] }
  let(:membership_tier) { nil }

  def leaf(entity:, key:, operator:, value: nil)
    { "entity" => entity, "key" => key, "operator" => operator, "value" => value }
  end

  describe "no restriction" do
    it "treats a nil node as always matching" do
      expect(evaluator.evaluate(nil)).to eq(true)
    end

    it "treats an empty hash node as always matching" do
      expect(evaluator.evaluate({})).to eq(true)
    end
  end

  describe "leaf operators" do
    describe "eq/ne" do
      it "eq matches equal values" do
        cart["currency"] = "USD"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "currency", operator: "eq", value: "USD"))).to eq(true)
      end

      it "eq rejects unequal values" do
        cart["currency"] = "USD"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "currency", operator: "eq", value: "EUR"))).to eq(false)
      end

      it "ne matches unequal values" do
        cart["currency"] = "USD"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "currency", operator: "ne", value: "EUR"))).to eq(true)
      end

      it "ne rejects equal values" do
        cart["currency"] = "USD"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "currency", operator: "ne", value: "USD"))).to eq(false)
      end
    end

    describe "gt/gte/lt/lte" do
      let(:cart) { { "points" => 10 } }

      it "gt is true when actual is strictly greater" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "points", operator: "gt", value: 5))).to eq(true)
      end

      it "gt is false when actual equals expected" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "points", operator: "gt", value: 10))).to eq(false)
      end

      it "gte is true when actual equals expected" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "points", operator: "gte", value: 10))).to eq(true)
      end

      it "lt is true when actual is strictly less" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "points", operator: "lt", value: 20))).to eq(true)
      end

      it "lte is true when actual equals expected" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "points", operator: "lte", value: 10))).to eq(true)
      end

      it "is false (not raising) when actual is nil" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "missing", operator: "gt", value: 5))).to eq(false)
      end

      it "is false (not raising) when expected is nil" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "points", operator: "gt", value: nil))).to eq(false)
      end

      it "is false (not raising) on a type-mismatched comparison" do
        cart["points"] = "ten"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "points", operator: "gt", value: 5))).to eq(false)
      end
    end

    describe "in/not_in" do
      let(:cart) { { "country" => "US" } }

      it "in matches when actual is in an array" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "country", operator: "in", value: %w[US CA]))).to eq(true)
      end

      it "in matches a bare (non-array) expected value" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "country", operator: "in", value: "US"))).to eq(true)
      end

      it "in rejects when actual is absent from the array" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "country", operator: "in", value: %w[CA MX]))).to eq(false)
      end

      it "not_in matches when actual is absent from the array" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "country", operator: "not_in", value: %w[CA MX]))).to eq(true)
      end

      it "not_in rejects when actual is present in the array" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "country", operator: "not_in", value: %w[US CA]))).to eq(false)
      end
    end

    describe "contains" do
      it "matches a substring" do
        cart["sku_prefix"] = "SUMMER-SALE"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "sku_prefix", operator: "contains", value: "SALE"))).to eq(true)
      end

      it "coerces a numeric actual via to_s" do
        cart["points"] = 12_345
        expect(evaluator.evaluate(leaf(entity: "cart", key: "points", operator: "contains", value: "234"))).to eq(true)
      end

      it "rejects when the substring isn't present" do
        cart["sku_prefix"] = "WINTER-SALE"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "sku_prefix", operator: "contains", value: "SUMMER"))).to eq(false)
      end
    end

    describe "is_null/is_not_null" do
      it "is_null matches a missing key" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "missing", operator: "is_null"))).to eq(true)
      end

      it "is_null rejects a present key" do
        cart["currency"] = "USD"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "currency", operator: "is_null"))).to eq(false)
      end

      it "is_not_null matches a present key" do
        cart["currency"] = "USD"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "currency", operator: "is_not_null"))).to eq(true)
      end

      it "is_not_null rejects a missing key" do
        expect(evaluator.evaluate(leaf(entity: "cart", key: "missing", operator: "is_not_null"))).to eq(false)
      end
    end

    it "returns nil (falsy) for an unrecognized operator" do
      expect(evaluator.evaluate(leaf(entity: "cart", key: "currency", operator: "near", value: "USD"))).to be_nil
    end
  end

  describe "entity resolution" do
    describe "cart" do
      let(:line_items) { [{ sku: "A", quantity: 2, unit_price: 10 }, { sku: "B", quantity: 1, unit_price: 5 }] }

      it "computes total from line_items, ignoring a spoofed cart total" do
        cart["total"] = 999
        expect(evaluator.evaluate(leaf(entity: "cart", key: "total", operator: "eq", value: 25.0))).to eq(true)
      end

      it "computes item_count from line_items, ignoring a spoofed cart item_count" do
        cart["item_count"] = 999
        expect(evaluator.evaluate(leaf(entity: "cart", key: "item_count", operator: "eq", value: 3))).to eq(true)
      end

      it "reads any other key straight from the raw cart hash" do
        cart["currency"] = "USD"
        expect(evaluator.evaluate(leaf(entity: "cart", key: "currency", operator: "eq", value: "USD"))).to eq(true)
      end
    end

    describe "customer" do
      let(:scheme) { create(:membership_scheme, name: "VIP") }
      let(:membership_tier) { create(:membership_tier, membership_scheme: scheme, name: "Gold") }

      it "reads membership_tier from the membership_tier: object, ignoring a spoofed customer membership_tier key" do
        customer["membership_tier"] = "platinum"
        expect(evaluator.evaluate(leaf(entity: "customer", key: "membership_tier", operator: "eq", value: "Gold"))).to eq(true)
      end

      it "reads membership_scheme through the membership tier's own scheme" do
        expect(evaluator.evaluate(leaf(entity: "customer", key: "membership_scheme", operator: "eq", value: "VIP"))).to eq(true)
      end

      it "resolves membership_tier/membership_scheme to nil when no tier is given" do
        evaluator_without_tier = described_class.new(cart: cart, customer: customer, line_items: line_items)
        expect(evaluator_without_tier.evaluate(leaf(entity: "customer", key: "membership_tier", operator: "is_null"))).to eq(true)
      end

      it "reads any other key straight from the raw customer hash" do
        customer["external_id"] = "cust-1"
        expect(evaluator.evaluate(leaf(entity: "customer", key: "external_id", operator: "eq", value: "cust-1"))).to eq(true)
      end
    end

    describe "line_item" do
      let(:line_item) { { "sku" => "A", "quantity" => 3 } }

      it "reads keys from the given line_item hash" do
        expect(evaluator.evaluate(leaf(entity: "line_item", key: "sku", operator: "eq", value: "A"))).to eq(true)
      end

      it "resolves to nil when no line_item was given" do
        evaluator_without_item = described_class.new(cart: cart, customer: customer, line_items: line_items)
        expect(evaluator_without_item.evaluate(leaf(entity: "line_item", key: "sku", operator: "is_null"))).to eq(true)
      end
    end

    it "resolves an unrecognized entity to nil" do
      expect(evaluator.evaluate(leaf(entity: "invoice", key: "total", operator: "is_null"))).to eq(true)
    end
  end

  describe "group operators" do
    let(:true_leaf) { leaf(entity: "cart", key: "a", operator: "is_null") }
    let(:false_leaf) { leaf(entity: "cart", key: "a", operator: "is_not_null") }

    describe "and" do
      it "is true when every condition is true" do
        expect(evaluator.evaluate({ "operator" => "and", "conditions" => [true_leaf, true_leaf] })).to eq(true)
      end

      it "is false when any condition is false" do
        expect(evaluator.evaluate({ "operator" => "and", "conditions" => [true_leaf, false_leaf] })).to eq(false)
      end

      it "is vacuously true with an empty conditions array" do
        expect(evaluator.evaluate({ "operator" => "and", "conditions" => [] })).to eq(true)
      end

      it "is vacuously true with a missing conditions key" do
        expect(evaluator.evaluate({ "operator" => "and" })).to eq(true)
      end
    end

    describe "or" do
      it "is true when any condition is true" do
        expect(evaluator.evaluate({ "operator" => "or", "conditions" => [false_leaf, true_leaf] })).to eq(true)
      end

      it "is false when every condition is false" do
        expect(evaluator.evaluate({ "operator" => "or", "conditions" => [false_leaf, false_leaf] })).to eq(false)
      end

      it "is vacuously false with an empty conditions array" do
        expect(evaluator.evaluate({ "operator" => "or", "conditions" => [] })).to eq(false)
      end
    end

    describe "not" do
      it "negates the single condition" do
        expect(evaluator.evaluate({ "operator" => "not", "conditions" => [true_leaf] })).to eq(false)
        expect(evaluator.evaluate({ "operator" => "not", "conditions" => [false_leaf] })).to eq(true)
      end

      it "only consults the first condition when more than one is given" do
        expect(evaluator.evaluate({ "operator" => "not", "conditions" => [false_leaf, true_leaf] })).to eq(true)
      end
    end

    it "recurses through nested groups" do
      tree = {
        "operator" => "and",
        "conditions" => [
          { "operator" => "or", "conditions" => [false_leaf, true_leaf] },
          true_leaf
        ]
      }
      expect(evaluator.evaluate(tree)).to eq(true)
    end
  end
end
