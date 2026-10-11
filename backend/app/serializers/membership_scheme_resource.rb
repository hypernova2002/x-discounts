# frozen_string_literal: true

class MembershipSchemeResource < ApplicationResource
  attribute :id, &:public_id
  attributes :name, :created_at, :updated_at

  many :membership_tiers, resource: MembershipTierResource, key: "tiers", if: proc { included?(:membership_tiers) }
end
