# frozen_string_literal: true

class DiscountEffect < Sequel::Model
  include ConditionTreeValidatable
  include PublicIdentifiable

  LOYALTY_EFFECT_TYPES = %w[points_per_currency points_flat points_per_item points_multiplier].freeze
  EFFECT_TYPES = (%w[percentage_off fixed_amount_off free_item] + LOYALTY_EFFECT_TYPES).freeze
  SCOPES = %w[cart line_item].freeze
  PUBLIC_ID_PREFIX = "eff"

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :discount

  def validate
    super
    validates_presence [:discount_id, :effect_type, :scope]
    validates_includes EFFECT_TYPES, :effect_type, allow_missing: true
    validates_includes SCOPES, :scope, allow_missing: true

    validate_target_condition
    validate_config
    validate_kind_compatibility
  end

  private

  def validate_target_condition
    if scope == "line_item"
      if target_condition.nil? || target_condition.empty?
        errors.add(:target_condition, "is required when scope is line_item")
      else
        condition_errors = []
        valid_condition_tree?(target_condition, condition_errors)
        condition_errors.each { |msg| errors.add(:target_condition, msg) }
      end
    elsif scope == "cart" && target_condition && !target_condition.empty?
      errors.add(:target_condition, "must be blank when scope is cart")
    end
  end

  def validate_config
    return unless EFFECT_TYPES.include?(effect_type)

    cfg = (config || {}).to_h.stringify_keys

    case effect_type
    when "percentage_off"
      percentage = cfg["percentage"]
      unless percentage.is_a?(Numeric) && percentage.positive? && percentage <= 100
        errors.add(:config, "percentage must be a number between 0 and 100")
      end
    when "fixed_amount_off"
      amount = cfg["amount"]
      errors.add(:config, "amount must be a positive number") unless amount.is_a?(Numeric) && amount.positive?
      errors.add(:config, "currency is required") unless cfg["currency"].is_a?(String) && !cfg["currency"].empty?
    when "free_item"
      validate_free_item_config(cfg)
    when "points_per_currency"
      rate = cfg["rate"]
      errors.add(:config, "rate must be a positive number") unless rate.is_a?(Numeric) && rate.positive?
    when "points_flat"
      points = cfg["points"]
      errors.add(:config, "points must be a positive integer") unless points.is_a?(Integer) && points.positive?
    when "points_per_item"
      errors.add(:scope, "must be line_item for points_per_item") unless scope == "line_item"
      points_per_item = cfg["points_per_item"]
      errors.add(:config, "points_per_item must be a positive integer") unless points_per_item.is_a?(Integer) && points_per_item.positive?
    when "points_multiplier"
      multiplier = cfg["multiplier"]
      errors.add(:config, "multiplier must be a number greater than 1") unless multiplier.is_a?(Numeric) && multiplier > 1
    end
  end

  def validate_kind_compatibility
    return unless discount && EFFECT_TYPES.include?(effect_type)

    is_loyalty_effect = LOYALTY_EFFECT_TYPES.include?(effect_type)
    if discount.kind == "loyalty" && !is_loyalty_effect
      errors.add(:effect_type, "must be a points-based effect for loyalty discounts")
    elsif discount.kind != "loyalty" && is_loyalty_effect
      errors.add(:effect_type, "is only valid for loyalty discounts")
    end
  end

  def validate_free_item_config(cfg)
    %w[buy_quantity get_quantity].each do |key|
      unless cfg[key].is_a?(Integer) && cfg[key].positive?
        errors.add(:config, "#{key} must be a positive integer")
      end
    end

    unless [true, false].include?(cfg["repeatable"])
      errors.add(:config, "repeatable must be true or false")
    end

    %w[buy_condition get_condition].each do |key|
      condition = cfg[key]
      if condition.nil? || !condition.is_a?(Hash) || condition.empty?
        errors.add(:config, "#{key} is required")
      else
        condition_errors = []
        valid_condition_tree?(condition, condition_errors)
        condition_errors.each { |msg| errors.add(:config, "#{key}.#{msg}") }
      end
    end
  end
end
