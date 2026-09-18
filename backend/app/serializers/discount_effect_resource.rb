# frozen_string_literal: true

class DiscountEffectResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :effect_type, :scope

  attribute(:target_condition) { |effect| effect.target_condition&.to_h }
  attribute(:config) { |effect| effect.config.to_h }
end
