# frozen_string_literal: true

class GiftShopItem < Sequel::Model
  PUBLIC_ID_PREFIX = "gift"

  include PublicIdentifiable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :project

  def validate
    super
    validates_presence %i[project_id name points_cost]
    validates_integer :points_cost, allow_missing: true
    errors.add(:points_cost, "must be a positive number") if points_cost && points_cost <= 0
    if stock
      validates_integer :stock
      errors.add(:stock, "must be zero or positive") if stock.negative?
    end
  end

  def photo?
    photo_filename.present?
  end

  def photo_path
    return nil unless photo?

    Rails.root.join("storage", "gift_shop_items", "#{public_id}#{File.extname(photo_filename)}")
  end

  def in_stock?
    stock.nil? || stock.positive?
  end
end
