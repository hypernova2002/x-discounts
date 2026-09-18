# frozen_string_literal: true

class DiscountEffectRequest < Dry::Struct
  include JsonModel::Schema

  CONFIG_CLASSES = {
    "percentage_off" => PercentageOffConfigRequest,
    "fixed_amount_off" => FixedAmountOffConfigRequest,
    "free_item" => FreeItemConfigRequest,
    "points_per_currency" => PointsPerCurrencyConfigRequest,
    "points_flat" => PointsFlatConfigRequest,
    "points_per_item" => PointsPerItemConfigRequest,
    "points_multiplier" => PointsMultiplierConfigRequest
  }.freeze

  transform_keys(&:to_sym)

  attribute :effect_type, JsonModel::Types::String.enum(*DiscountEffect::EFFECT_TYPES)
  attribute :scope, JsonModel::Types::String.enum(*DiscountEffect::SCOPES)
  attribute? :target_condition, ConditionNode.optional
  attribute :config, JsonModel::Types::Hash

  def typed_config
    CONFIG_CLASSES.fetch(effect_type).new(config)
  end
end
