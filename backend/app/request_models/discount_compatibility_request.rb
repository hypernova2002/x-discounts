# frozen_string_literal: true

class DiscountCompatibilityRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :compatible_discount_id, JsonModel::Types::String.constrained(min_size: 1)
end
