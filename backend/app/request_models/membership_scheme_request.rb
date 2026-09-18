# frozen_string_literal: true

class MembershipSchemeRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :name, JsonModel::Types::String.constrained(min_size: 1)
end
