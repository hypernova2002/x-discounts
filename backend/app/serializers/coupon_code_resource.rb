# frozen_string_literal: true

class CouponCodeResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :code, :max_redemptions, :created_at

  attribute(:redemption_count) { |cc| cc.redemption_count }
  attribute(:remaining_redemptions) { |cc| cc.remaining_redemptions }
  attribute(:customer) do |cc|
    cc.customer && { id: cc.customer.public_id, external_id: cc.customer.external_id, name: cc.customer.name }
  end
end
