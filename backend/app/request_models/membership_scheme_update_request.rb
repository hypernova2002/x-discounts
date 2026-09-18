# frozen_string_literal: true

class MembershipSchemeUpdateRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute? :name, JsonModel::Types::String.constrained(min_size: 1)
end
