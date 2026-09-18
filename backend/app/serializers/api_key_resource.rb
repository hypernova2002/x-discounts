# frozen_string_literal: true

class ApiKeyResource
  include Alba::Resource

  attribute :id, &:public_id
  attribute(:user_id) { |key| key.user.public_id }
  attributes :name, :role, :token_last_four, :last_used_at, :revoked_at, :created_at

  # The raw token only ever exists on the instance that just generated it — never
  # persisted, never retrievable again. Only include it when explicitly asked to
  # (right after creation), via params: { include_token: true }.
  attribute(:token, if: proc { params[:include_token] }) { |key| key.raw_token }
end
