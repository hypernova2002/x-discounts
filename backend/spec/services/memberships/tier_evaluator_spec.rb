require "rails_helper"

RSpec.describe Memberships::TierEvaluator do
  let(:project) { create(:project) }
  let(:customer) { create(:customer, project: project) }
  let(:evaluator) { described_class.new(customer: customer, now: now) }
  let(:now) { Time.utc(2026, 6, 1) }

  def leaf(key:, operator:, value: nil, window_days: nil)
    { "key" => key, "operator" => operator, "value" => value, "window_days" => window_days }
  end

  describe "no restriction" do
    it "treats a nil node as always matching" do
      expect(evaluator.evaluate(nil)).to eq(true)
    end

    it "treats an empty hash node as always matching" do
      expect(evaluator.evaluate({})).to eq(true)
    end
  end

  describe "resolvable keys (lifetime)" do
    before do
      order_a = create(:order, project: project, customer: customer, total_amount: 100, created_at: now - 1.day)
      order_b = create(:order, project: project, customer: customer, total_amount: 50, created_at: now - 2.days)
      create(:order_line_item, order: order_a, quantity: 3)
      create(:order_line_item, order: order_b, quantity: 2)
      create(:loyalty_point_lot, customer: customer, order: order_a, points: 40, source: "order")
      create(:loyalty_point_lot, customer: customer, order: order_b, points: 10, source: "order")
      create(:loyalty_point_lot, customer: customer, points: 1000, source: "manual_grant")
    end

    it "resolves total_spent as the sum of the customer's order totals" do
      expect(evaluator.evaluate(leaf(key: "total_spent", operator: "eq", value: 150.0))).to eq(true)
    end

    it "resolves order_count as the customer's order count" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "eq", value: 2))).to eq(true)
    end

    it "resolves item_count as the summed line-item quantity across the customer's orders" do
      expect(evaluator.evaluate(leaf(key: "item_count", operator: "eq", value: 5))).to eq(true)
    end

    it "resolves points_earned as only order-sourced lots, excluding a manual_grant" do
      expect(evaluator.evaluate(leaf(key: "points_earned", operator: "eq", value: 50))).to eq(true)
    end
  end

  describe "window_days" do
    before do
      create(:order, project: project, customer: customer, total_amount: 100, created_at: now - 5.days)
      create(:order, project: project, customer: customer, total_amount: 999, created_at: now - 40.days)
    end

    it "includes only orders inside the window for total_spent" do
      expect(evaluator.evaluate(leaf(key: "total_spent", operator: "eq", value: 100.0, window_days: 10))).to eq(true)
    end

    it "includes only orders inside the window for order_count" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "eq", value: 1, window_days: 10))).to eq(true)
    end

    it "includes every order when window_days is absent (lifetime)" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "eq", value: 2))).to eq(true)
    end
  end

  it "resolves an unrecognized key to nil" do
    expect(evaluator.evaluate(leaf(key: "favorite_color", operator: "is_null"))).to eq(true)
  end

  describe "operators" do
    before { create_list(:order, 3, project: project, customer: customer) }

    it "eq matches equal values" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "eq", value: 3))).to eq(true)
    end

    it "eq rejects unequal values" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "eq", value: 5))).to eq(false)
    end

    it "ne rejects equal values" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "ne", value: 3))).to eq(false)
    end

    it "gt is true when actual is strictly greater" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "gt", value: 2))).to eq(true)
    end

    it "gte is true when actual equals expected" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "gte", value: 3))).to eq(true)
    end

    it "lt is true when actual is strictly less" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "lt", value: 5))).to eq(true)
    end

    it "lte is true when actual equals expected" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "lte", value: 3))).to eq(true)
    end

    it "is_null matches a customer with no orders" do
      empty_evaluator = described_class.new(customer: create(:customer, project: project), now: now)
      expect(empty_evaluator.evaluate(leaf(key: "total_spent", operator: "is_null"))).to eq(false)
    end

    it "is_not_null matches a resolvable key" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "is_not_null"))).to eq(true)
    end

    it "is false (not raising) when expected is nil for a gt comparison" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "gt", value: nil))).to eq(false)
    end

    it "is false (not raising) on a type-mismatched comparison" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "gt", value: "three"))).to eq(false)
    end

    it "does not support in, even when the value would obviously match" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "in", value: [3, 4]))).to be_nil
    end

    it "does not support not_in" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "not_in", value: [99]))).to be_nil
    end

    it "does not support contains" do
      expect(evaluator.evaluate(leaf(key: "order_count", operator: "contains", value: "3"))).to be_nil
    end
  end

  describe "group operators" do
    before { create_list(:order, 3, project: project, customer: customer) }

    let(:true_leaf) { leaf(key: "order_count", operator: "gte", value: 1) }
    let(:false_leaf) { leaf(key: "order_count", operator: "gte", value: 99) }

    it "and is true only when every condition is true" do
      expect(evaluator.evaluate({ "operator" => "and", "conditions" => [true_leaf, true_leaf] })).to eq(true)
      expect(evaluator.evaluate({ "operator" => "and", "conditions" => [true_leaf, false_leaf] })).to eq(false)
    end

    it "or is true when any condition is true" do
      expect(evaluator.evaluate({ "operator" => "or", "conditions" => [false_leaf, true_leaf] })).to eq(true)
    end

    it "not negates the single condition" do
      expect(evaluator.evaluate({ "operator" => "not", "conditions" => [true_leaf] })).to eq(false)
    end

    it "recurses through nested groups" do
      tree = { "operator" => "and", "conditions" => [{ "operator" => "or", "conditions" => [false_leaf, true_leaf] }, true_leaf] }
      expect(evaluator.evaluate(tree)).to eq(true)
    end
  end
end
