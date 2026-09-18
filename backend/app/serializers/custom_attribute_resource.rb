# frozen_string_literal: true

class CustomAttributeResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :entity, :key, :data_type, :created_at, :updated_at
end
