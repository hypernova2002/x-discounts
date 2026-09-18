# frozen_string_literal: true

# membership_tier_id is nullable and optional — omitted means "leave unchanged",
# explicit null means "unassign the customer's membership" (attributes.key? tells
# these apart), a non-null value means "assign to this tier".
class CustomerUpdateRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :membership_tier_id, JsonModel::Types::String.optional
end
