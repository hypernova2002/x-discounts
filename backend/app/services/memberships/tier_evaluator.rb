# frozen_string_literal: true

module Memberships
  # Evaluates a MembershipTier#requirements_condition tree against a customer's
  # actual order history — unlike Discounts::ConditionEvaluator (which checks a
  # submitted cart/customer against a tree), this queries the database directly,
  # since tier requirements are about historical activity, not a specific request.
  class TierEvaluator
    def initialize(customer:, now: Time.now.utc)
      @customer = customer
      @now = now
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
      actual = resolve(node["key"], node["window_days"])
      apply_operator(node["operator"], actual, node["value"])
    end

    # total_spent/order_count/item_count/points_earned are the only keys this
    # supports — reserved, computed, and windowable by an arbitrary number of days
    # (nil/absent window_days means lifetime).
    def resolve(key, window_days)
      case key
      when "total_spent" then orders_dataset(window_days).sum(:total_amount).to_f
      when "order_count" then orders_dataset(window_days).count
      when "item_count" then item_count(window_days)
      when "points_earned" then points_earned(window_days)
      end
    end

    def orders_dataset(window_days)
      dataset = @customer.orders_dataset
      return dataset unless window_days.present?

      cutoff = @now - window_days.to_i.days
      dataset.where { created_at >= cutoff }
    end

    def item_count(window_days)
      order_ids = orders_dataset(window_days).select(:id)
      OrderLineItem.where(order_id: order_ids).sum(:quantity).to_i
    end

    # Only order-driven earning counts toward a tier requirement — a manual grant or
    # a redemption-refund credit isn't "activity" a tier should reward.
    def points_earned(window_days)
      order_ids = orders_dataset(window_days).select(:id)
      LoyaltyPointLot.where(order_id: order_ids, source: "order").sum(:points).to_i
    end

    def apply_operator(operator, actual, expected)
      case operator
      when "eq" then actual == expected
      when "ne" then actual != expected
      when "gt" then compare(actual, expected) { |a, b| a > b }
      when "gte" then compare(actual, expected) { |a, b| a >= b }
      when "lt" then compare(actual, expected) { |a, b| a < b }
      when "lte" then compare(actual, expected) { |a, b| a <= b }
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
