# frozen_string_literal: true

class MembershipSchemeResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :name, :created_at, :updated_at

  many :membership_tiers, resource: MembershipTierResource, key: "tiers"
end
