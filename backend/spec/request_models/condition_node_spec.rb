require "rails_helper"

RSpec.describe ConditionNode do
  describe "#group?/#leaf?" do
    ConditionVocabulary::GROUP_OPERATORS.each do |op|
      it "treats #{op} as a group, not a leaf" do
        node = described_class.new(operator: op)
        expect(node.group?).to eq(true)
        expect(node.leaf?).to eq(false)
      end
    end

    ConditionVocabulary::LEAF_OPERATORS.each do |op|
      it "treats #{op} as a leaf, not a group" do
        node = described_class.new(operator: op)
        expect(node.leaf?).to eq(true)
        expect(node.group?).to eq(false)
      end
    end

    it "is neither for an unrecognized operator" do
      node = described_class.new(operator: "bogus")
      expect(node.group?).to eq(false)
      expect(node.leaf?).to eq(false)
    end
  end

  describe "#validate" do
    let(:errors) { [] }

    it "accepts a valid leaf and leaves errors empty" do
      node = described_class.new(entity: "cart", key: "subtotal", operator: "gte", value: 50)
      expect(node.validate(errors)).to eq(true)
      expect(errors).to be_empty
    end

    it "accepts a nullary-operator leaf (is_null) with no value" do
      node = described_class.new(entity: "customer", key: "email", operator: "is_null")
      expect(node.validate(errors)).to eq(true)
    end

    it "accepts a nullary-operator leaf (is_not_null) with no value" do
      node = described_class.new(entity: "customer", key: "email", operator: "is_not_null")
      expect(node.validate(errors)).to eq(true)
    end

    it "rejects a non-nullary leaf missing its value" do
      node = described_class.new(entity: "cart", key: "subtotal", operator: "gte")
      expect(node.validate(errors)).to eq(false)
      expect(errors).to include(a_string_matching(/value is required/))
    end

    it "rejects a leaf with an entity outside ConditionVocabulary::ENTITIES" do
      node = described_class.new(entity: "invoice", key: "subtotal", operator: "gte", value: 50)
      expect(node.validate(errors)).to eq(false)
      expect(errors).to include(a_string_matching(/entity must be one of/))
    end

    it "rejects a leaf with a missing entity" do
      node = described_class.new(key: "subtotal", operator: "gte", value: 50)
      expect(node.validate(errors)).to eq(false)
    end

    it "rejects a leaf with an empty key" do
      node = described_class.new(entity: "cart", key: "", operator: "gte", value: 50)
      expect(node.validate(errors)).to eq(false)
      expect(errors).to include(a_string_matching(/key must be a non-empty string/))
    end

    it "rejects a leaf with a missing key" do
      node = described_class.new(entity: "cart", operator: "gte", value: 50)
      expect(node.validate(errors)).to eq(false)
    end

    it "reports every failing rule on a leaf, not just the first" do
      node = described_class.new(entity: "invoice", key: "", operator: "gte")
      node.validate(errors)
      expect(errors.size).to eq(3)
    end

    it "accepts a valid 'and' group of leaves" do
      node = described_class.new(operator: "and", conditions: [
        { entity: "cart", key: "subtotal", operator: "gte", value: 50 },
        { entity: "customer", key: "country", operator: "eq", value: "US" }
      ])
      expect(node.validate(errors)).to eq(true)
      expect(errors).to be_empty
    end

    it "accepts a valid 'or' group of leaves" do
      node = described_class.new(operator: "or", conditions: [{ entity: "cart", key: "subtotal", operator: "gte", value: 50 }])
      expect(node.validate(errors)).to eq(true)
    end

    it "accepts 'not' with exactly one condition" do
      node = described_class.new(operator: "not", conditions: [{ entity: "cart", key: "subtotal", operator: "gte", value: 50 }])
      expect(node.validate(errors)).to eq(true)
    end

    it "rejects 'not' with more than one condition" do
      node = described_class.new(operator: "not", conditions: [
        { entity: "cart", key: "subtotal", operator: "gte", value: 50 },
        { entity: "cart", key: "subtotal", operator: "lte", value: 100 }
      ])
      expect(node.validate(errors)).to eq(false)
      expect(errors).to include(a_string_matching(/'not' requires exactly one condition/))
    end

    it "rejects a group with a missing conditions array" do
      node = described_class.new(operator: "and")
      expect(node.validate(errors)).to eq(false)
      expect(errors).to include(a_string_matching(/requires a non-empty 'conditions' array/))
    end

    it "rejects a group with an empty conditions array" do
      node = described_class.new(operator: "and", conditions: [])
      expect(node.validate(errors)).to eq(false)
    end

    it "rejects an unrecognized top-level operator" do
      node = described_class.new(operator: "xor")
      expect(node.validate(errors)).to eq(false)
      expect(errors).to include(a_string_matching(/operator must be one of/))
    end

    it "rejects a completely empty node (no operator at all)" do
      node = described_class.new({})
      expect(node.validate(errors)).to eq(false)
    end

    it "recurses into nested groups and reports the real nested path" do
      node = described_class.new(operator: "and", conditions: [
        {
          operator: "or",
          conditions: [
            { entity: "cart", key: "subtotal", operator: "gte", value: 50 },
            { entity: "invoice", key: "bad", operator: "gte", value: 1 }
          ]
        }
      ])
      expect(node.validate(errors)).to eq(false)
      expect(errors).to include(a_string_matching(/\Aroot\.conditions\[0\]\.conditions\[1\]:/))
    end

    it "stops a deeply valid tree from reporting any error" do
      node = described_class.new(operator: "and", conditions: [
        { operator: "or", conditions: [{ entity: "cart", key: "subtotal", operator: "gte", value: 50 }] },
        { entity: "customer", key: "country", operator: "in", value: %w[US CA] }
      ])
      expect(node.validate(errors)).to eq(true)
      expect(errors).to be_empty
    end
  end

  describe "Dry::Struct shape" do
    it "accepts a completely empty hash (domain rules live in #validate, not the struct shape)" do
      expect { described_class.new({}) }.not_to raise_error
    end

    it "accepts an arbitrary value type (Any)" do
      expect(described_class.new(value: { nested: "hash" }).value).to eq({ nested: "hash" })
    end

    it "accepts window_days for windowable aggregate keys" do
      expect(described_class.new(window_days: 30).window_days).to eq(30)
    end

    it "rejects a non-integer window_days" do
      expect { described_class.new(window_days: "thirty") }.to raise_error(Dry::Struct::Error)
    end
  end
end
