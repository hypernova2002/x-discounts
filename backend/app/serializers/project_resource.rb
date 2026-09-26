# frozen_string_literal: true

class ProjectResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :name, :timezone, :currency, :created_at, :updated_at
end
