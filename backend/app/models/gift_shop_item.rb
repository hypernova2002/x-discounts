# frozen_string_literal: true

class GiftShopItem < Sequel::Model
  PUBLIC_ID_PREFIX = "gift"

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers

  many_to_one :project

  def validate
    super
    validates_presence %i[project_id name points_cost]
    validates_utf8_length :name, max: 1000
    validates_utf8_length :description, max: 10_000
    validates_utf8_length :photo_filename, max: 255
    validates_utf8_length :photo_content_type, max: 255
    validates_bounded_number :points_cost, min: 1, max: 10_000_000, integer_only: true
    validates_bounded_number :stock, min: 0, max: 10_000_000, integer_only: true
    validates_boolean :enabled
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
