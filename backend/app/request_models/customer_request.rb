# frozen_string_literal: true

class CustomerRequest < Dry::Struct
  include JsonModel::Schema

  transform_keys(&:to_sym)

  attribute :external_id, JsonModel::Types::String.constrained(min_size: 1)
  attribute? :name, JsonModel::Types::String.optional
  attribute? :email, JsonModel::Types::String.optional
  attribute? :phone_number, JsonModel::Types::String.optional
  attribute? :country, JsonModel::Types::String.optional
  attribute? :date_of_birth, JsonModel::Types::String.optional
  attribute? :marketing_opt_in, JsonModel::Types::Bool.optional
  attribute? :metadata, JsonModel::Types::Hash.optional
end
