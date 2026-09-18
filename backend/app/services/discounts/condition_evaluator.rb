# frozen_string_literal: true

module Discounts
  # Evaluates a condition tree (the same shape ConditionTreeValidatable validates)
  # against real request-time data, rather than just checking its shape. A missing
  # key and an explicit null are treated identically — both resolve to nil — matching
  # the is_null/is_not_null semantics decided when those operators were added.
  class ConditionEvaluator
    def initialize(cart:, customer:, line_item: nil, line_items: [], membership_tier: nil)
      @cart = cart
      @customer = customer
      @line_item = line_item
      @line_items = line_items
      @membership_tier = membership_tier
    end

    def evaluate(node)
      node = node.to_h if node.respond_to?(:to_h) && !node.is_a?(Hash)
      return true if node.nil? || node.empty?

      node = node.stringify_keys

      if ConditionVocabulary::GROUP_OPERATORS.include?(node["operator"])
        evaluate_group(node)
      else
        evaluate_leaf(node)
      end
    end

    private

    def evaluate_group(node)
      conditions = node["conditions"] || []

      case node["operator"]
      when "and" then conditions.all? { |c| evaluate(c) }
      when "or" then conditions.any? { |c| evaluate(c) }
      when "not" then !evaluate(conditions.first)
      end
    end

    def evaluate_leaf(node)
      actual = resolve(node["entity"], node["key"])
      apply_operator(node["operator"], actual, node["value"])
    end

    def resolve(entity, key)
      case entity
      when "cart" then cart_value(key)
      when "customer" then customer_value(key)
      when "line_item" then @line_item&.[](key)
      end
    end

    # total/item_count are reserved, computed keys — always derived from the actual
    # line items rather than read from @cart, so a client can't spoof them by
    # submitting cart: { total: ... } directly.
    def cart_value(key)
      case key
      when "total" then @line_items.sum { |li| li[:quantity].to_f * li[:unit_price].to_f }
      when "item_count" then @line_items.sum { |li| li[:quantity].to_i }
      else @cart[key]
      end
    end

    # membership_tier/membership_scheme are reserved, computed keys too — looked up
    # server-side from the customer's actual persisted membership (see ValidationService),
    # never read from @customer, so a client can't grant themselves a tier by submitting
    # customer: { membership_tier: "gold" } directly.
    def customer_value(key)
      case key
      when "membership_tier" then @membership_tier&.name
      when "membership_scheme" then @membership_tier&.membership_scheme&.name
      else @customer[key]
      end
    end

    def apply_operator(operator, actual, expected)
      case operator
      when "eq" then actual == expected
      when "ne" then actual != expected
      when "gt" then compare(actual, expected) { |a, b| a > b }
      when "gte" then compare(actual, expected) { |a, b| a >= b }
      when "lt" then compare(actual, expected) { |a, b| a < b }
      when "lte" then compare(actual, expected) { |a, b| a <= b }
      when "in" then Array(expected).include?(actual)
      when "not_in" then !Array(expected).include?(actual)
      when "contains" then actual.to_s.include?(expected.to_s)
      when "is_null" then actual.nil?
      when "is_not_null" then !actual.nil?
      end
    end

    def compare(actual, expected)
      return false if actual.nil? || expected.nil?

      yield(actual, expected)
    rescue ArgumentError, TypeError
      false
    end
  end
end
