# frozen_string_literal: true

class CouponCodeResource < ApplicationResource
  attribute :id, &:public_id
  attributes :code, :max_redemptions, :created_at

  attribute(:redemption_count, if: proc { included?(:redemption_count) }) do |cc|
    params[:redemption_counts]&.fetch(cc.id, nil) || cc.redemption_count
  end
  attribute(:remaining_redemptions, if: proc { included?(:remaining_redemptions) }) { |cc| cc.remaining_redemptions }
  attribute(:customer, if: proc { included?(:customer) }) do |cc|
    cc.customer && { id: cc.customer.public_id, external_id: cc.customer.external_id, name: cc.customer.name }
  end
end
