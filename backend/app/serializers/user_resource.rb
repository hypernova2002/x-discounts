# frozen_string_literal: true

class UserResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :name, :email, :locale, :otp_enabled, :created_at, :updated_at
end
