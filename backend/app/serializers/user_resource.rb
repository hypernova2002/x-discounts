# frozen_string_literal: true

class UserResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :name, :email, :locale, :created_at, :updated_at
end
