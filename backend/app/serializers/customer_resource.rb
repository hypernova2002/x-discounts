# frozen_string_literal: true

class CustomerResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :external_id, :name, :email, :phone_number, :country, :date_of_birth, :marketing_opt_in,
             :membership_tier_entered_at, :created_at, :updated_at

  attribute(:metadata) { |customer| customer.metadata.to_h }

  one :membership_tier, resource: MembershipTierResource
end
