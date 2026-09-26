# frozen_string_literal: true

class DiscountResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :key, :kind, :name, :stackable, :refundable, :enabled, :created_at, :updated_at,
             :max_redemptions, :max_redemptions_per_customer, :max_redemptions_per_day,
             :max_redemption_amount, :max_redemption_amount_per_day, :max_redemption_amount_per_customer

  attribute(:eligibility_condition) { |discount| discount.eligibility_condition.to_h }

  # kind_config lives once on the discount now (no more promotions/coupons/loyalties
  # child tables) — reshaped back into the old per-kind nesting here so the API
  # contract (and the frontend reading it) doesn't need to change.
  attribute(:promotion) { |d| d.kind == "promotion" ? d.kind_config.to_h : nil }
  # The image's own upload metadata (filename/content-type/byte-size) is an
  # internal storage detail, not something the frontend needs — it gets a
  # computed design_image_url instead, same shape as GiftShopItemResource#photo_url.
  attribute(:coupon) do |d|
    next nil unless d.kind == "coupon"

    d.kind_config.to_h
     .except("design_image_filename", "design_image_content_type", "design_image_byte_size")
     .merge(design_image_url: d.design_image? ? "/api/v1/admin/discounts/#{d.public_id}/design_image" : nil)
  end
  attribute(:loyalty) { |d| d.kind == "loyalty" ? d.kind_config.to_h : nil }

  attribute(:compatible_discounts) do |d|
    d.compatible_discounts.map { |cd| { id: cd.public_id, name: cd.name, key: cd.key } }
  end

  attribute(:coupon_code_stats) do |d|
    next nil unless d.kind == "coupon"

    codes = d.coupon_codes_dataset.all
    { total: codes.size, available: codes.count { |c| c.remaining_redemptions.positive? } }
  end

  attribute(:redemption_count) { |d| d.redemption_count }
  attribute(:points_earned) { |d| d.kind == "loyalty" ? d.points_earned : nil }
  attribute(:points_redeemed) { |d| d.kind == "loyalty" ? d.points_redeemed : nil }

  one :campaign, resource: CampaignResource
  many :discount_effects, resource: DiscountEffectResource, key: "effects"
end
