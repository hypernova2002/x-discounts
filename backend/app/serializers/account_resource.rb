# frozen_string_literal: true

class AccountResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :name, :otp_required, :created_at, :updated_at
end
